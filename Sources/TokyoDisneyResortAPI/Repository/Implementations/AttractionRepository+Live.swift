//
//  AttractionRepository+Live.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/01.
//

import Dependencies
import Foundation
import Vapor

extension AttractionRepository: DependencyKey {
    static var liveValue: Self {
        @Dependency(\.cacheStore) var cacheStore
        
        let apiClient: TokyoDisneyResortClient = .init()
        let htmlParser: AttractionHTMLParser = .init()
        let dataMapper: AttractionDataMapper = .init()
        
        @Sendable func generateIntegratedInfoCacheKey(parkType: ParkType) -> String {
            return "\(parkType.rawValue)_integrated_attraction_info"
        }
        
        /// https://www.tokyodisneyresort.jp/tdl/attraction.html または
        /// https://www.tokyodisneyresort.jp/tds/attraction.html の情報を取得
        @Sendable func fetchAttractionBasicInfo(parkType: ParkType) async throws -> [Attraction] {
            do {
                // APIクライアントからHTMLを取得
                let htmlString = try await apiClient.fetchAttractionHTML(parkType: parkType)
                
                // HTML 解析でAttraction（基本情報のみ）を抽出
                let attractions = try htmlParser.parseAttractions(from: htmlString)
                
                return attractions
            } catch HTMLParserError.noAttractionFound {
                // アトラクションデータが見つからない場合、フォールバックデータを返す
                return dataMapper.createFallbackAttractions()
            } catch {
                throw error
            }
        }
        
        /// JSONからアトラクション運営状況を取得
        @Sendable func fetchOperatingStatus(parkType: ParkType, request: Request) async throws -> [Attraction] {
            do {
                // API クライアントからアトラクション運営状況データを取得
                let jsonData = try await apiClient.fetchOperatingStatus(parkType: parkType)
                
                // デバッグ用にJSONデータをログに出力
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    request.logger.debug("Received JSON: \(String(jsonString.prefix(100)))...")
                }
                
                // JSONを直接Attractionモデルにデコードするためのカスタムデコーダーが必要
                let decoder = JSONDecoder()
                do {
                    let operatingStatusArray = try decoder.decode([Attraction].self, from: jsonData)
                    request.logger.info("Successfully decoded \(operatingStatusArray.count) attractions")
                    return operatingStatusArray
                } catch let decodingError {
                    request.logger.error("Failed to decode attractions: \(decodingError)")
                    throw decodingError
                }
            } catch {
                request.logger.error("Failed to fetch operating status: \(error.localizedDescription)")
                throw APIError.decodingFailed
            }
        }
        
        @Sendable func getCachedIntegratedInfo(parkType: ParkType, request: Request) async throws -> [Attraction]? {
            let key = generateIntegratedInfoCacheKey(parkType: parkType)
            return try await cacheStore.get(key, as: [Attraction].self, request: request)
        }
        
        @Sendable func setCacheIntegratedInfo(attractions: [Attraction], parkType: ParkType, request: Request) async throws {
            let key = generateIntegratedInfoCacheKey(parkType: parkType)
            let cacheTTL = CacheExpirationTime.seconds(300)
            try await cacheStore.set(key, to: attractions, expiresIn: cacheTTL, request: request)
        }
        
        return .init(
            getIntegratedAttractionInfo: { parkType, request in
                // 先にキャッシュからの取得を試みる
                // キャッシュが存在すれば、キャッシュを返す
                if let cachedAttractions = try await getCachedIntegratedInfo(parkType: parkType, request: request) {
                    request.logger.info("Using cached integrated attractions for \(parkType.rawValue)")
                    return cachedAttractions
                }
                
                request.logger.info("Fetching fresh attraction data for \(parkType.rawValue)")
                
                // HTMLからの基本情報取得
                let basicInfoList = try await fetchAttractionBasicInfo(parkType: parkType)
                
                // JSONからの運営状況取得
                let operatingStatusList = try await fetchOperatingStatus(parkType: parkType, request: request)
                
                // データ統合
                let attractions = dataMapper.integrateAttractionData(
                    basicInfoList: basicInfoList,
                    operatingStatusList: operatingStatusList
                )
                
                // 統合データをキャッシュに保存
                try await setCacheIntegratedInfo(
                    attractions: attractions,
                    parkType: parkType,
                    request: request
                )
                
                return attractions
            }
        )
    }
}
