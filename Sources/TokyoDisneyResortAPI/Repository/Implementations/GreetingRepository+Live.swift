//
//  GreetingRepository+Live.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/18.
//

import Dependencies
import Foundation
import Vapor

extension GreetingRepository: CacheableEntity {
    /// キャッシュの有効期限（デフォルト：10分）
    static var cacheExpirationTime: CacheExpirationTime { .minutes(10) }
    
    /// 指定されたパークタイプのグリーティングキャッシュキーを生成
    /// - Parameter parkType: パークタイプ (TDL/TDS)
    /// - Returns: キャッシュキー
    static func cacheKey(for parkType: ParkType) -> String {
        return "greetings_\(parkType.rawValue)"
    }
}

extension GreetingRepository: DependencyKey {
    static var liveValue: Self {
        @Dependency(\.cacheStore) var cacheStore
        @Dependency(\.request) var request
        
        let apiFetcher = APIFetcher<Greeting>()
        let greetingHTMLParser: GreetingHTMLParser = .init()
        let greetingDataMapper: GreetingDataMapper = .init()
        
        let facilityType: FacilityType = .greeting
        
        return .init(
            execute: { parkType in
                // キャッシュからの取得を試みる
                if let cachedGreetings = try await cacheStore.get(
                    cacheKey(for: parkType),
                    as: [Greeting].self
                ) {
                    request.logger.info("Using cached greeting info for \(parkType.rawValue)")
                    return cachedGreetings
                }
                
                request.logger.info("Fetching fresh greeting data for \(parkType.rawValue)")
                
                do {
                    // APIから基本情報と運営状況を取得
                    async let basicInfoTask = apiFetcher.fetchBasicInfo(
                        parkType: parkType,
                        facilityType: facilityType,
                        parser: greetingHTMLParser
                    )
                    
                    async let operatingStatusTask = apiFetcher.fetchOperatingStatus(
                        parkType: parkType,
                        facilityType: facilityType
                    )
                    
                    // 並行して取得した情報を待機
                    let (basicInfoList, operatingStatusList) = try await (basicInfoTask, operatingStatusTask)
                    
                    // データを統合
                    let greetings = greetingDataMapper.integrateGreetingData(
                        basicInfoList: basicInfoList,
                        operatingStatusList: operatingStatusList
                    )
                    
                    // 統合データをキャッシュに保存
                    try await cacheStore.set(
                        cacheKey(for: parkType),
                        to: greetings,
                        expiresIn: cacheExpirationTime
                    )
                    
                    return greetings
                } catch let error as any AbortError {
                    // AbortErrorに準拠したエラーはそのまま上に伝播
                    request.logger.error("Failed to fetch greeting data: \(error.reason)")
                    throw error
                } catch {
                    // その他のエラーは適切なHTTPエラーにラップ
                    request.logger.error("Failed to fetch greeting data: \(error.localizedDescription)")
                    throw Abort(.internalServerError, reason: "Failed to fetch greeting data: \(error.localizedDescription)")
                }
            }
        )
    }
}
