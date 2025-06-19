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
        
        let apiFetcher = APIFetcher<Attraction>()
        let attractionHTMLParser: AttractionHTMLParser = .init()
        let dataMapper: AttractionDataMapper = .init()
        
        // RepositoryProtocol の実装
        let facilityType: FacilityType = .attraction
        let cacheExpirationTime: CacheExpirationTime = .minutes(10)
        
        @Sendable func cacheKey(for parkType: ParkType) -> String {
            return "attractions_\(parkType.rawValue)"
        }
        
        return .init(
            execute: { parkType, request in
                // キャッシュからの取得を試みる
                if let cachedAttractions = try await cacheStore.get(
                    cacheKey(for: parkType),
                    as: [Attraction].self,
                    request: request
                ) {
                    request.logger.info("Using cached integrated attractions for \(parkType.rawValue)")
                    return cachedAttractions
                }
                
                request.logger.info("Fetching fresh attraction data for \(parkType.rawValue)")
                
                do {
                    // APIから基本情報と運営状況を取得
                    async let basicInfoTask = apiFetcher.fetchBasicInfo(
                        parkType: parkType, 
                        facilityType: facilityType,
                        parser: attractionHTMLParser
                    )
                    
                    async let operatingStatusTask = apiFetcher.fetchOperatingStatus(
                        parkType: parkType,
                        facilityType: facilityType,
                        request: request
                    )
                    
                    // 並行して取得した情報を待機
                    let (basicInfoList, operatingStatusList) = try await (basicInfoTask, operatingStatusTask)
                    
                    // データを統合
                    let attractions = dataMapper.integrateAttractionData(
                        basicInfoList: basicInfoList,
                        operatingStatusList: operatingStatusList
                    )
                    
                    // 統合データをキャッシュに保存
                    try await cacheStore.set(
                        cacheKey(for: parkType),
                        to: attractions,
                        expiresIn: cacheExpirationTime,
                        request: request
                    )
                    
                    return attractions
                } catch let error as any AbortError {
                    // AbortErrorに準拠したエラーはそのまま上に伝播
                    request.logger.error("Failed to fetch attraction data: \(error.reason)")
                    throw error
                } catch {
                    // その他のエラーは適切なHTTPエラーにラップ
                    request.logger.error("Failed to fetch attraction data: \(error.localizedDescription)")
                    throw Abort(.internalServerError, reason: "Failed to fetch attraction data: \(error.localizedDescription)")
                }
            }
        )
    }
}
