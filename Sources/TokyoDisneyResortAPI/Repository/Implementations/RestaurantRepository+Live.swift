//
//  RestaurantRepository+Live.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/24.
//

import Dependencies
import Foundation
import Vapor

extension RestaurantRepository: CacheableEntity {
    /// キャッシュの有効期限（デフォルト：10分）
    static var cacheExpirationTime: CacheExpirationTime { .minutes(10) }
    
    /// 指定されたパークタイプのレストランキャッシュキーを生成
    /// - Parameter parkType: パークタイプ (TDL/TDS)
    /// - Returns: キャッシュキー
    static func cacheKey(for parkType: ParkType) -> String {
        return "restaurants_\(parkType.rawValue)"
    }
}

extension RestaurantRepository: DependencyKey {
    
    static var liveValue: Self {
        @Dependency(\.cacheStore) var cacheStore
        @Dependency(\.request) var request
        
        let apiFetcher = APIFetcher<Restaurant>()
        let restaurantHTMLParser: RestaurantHTMLParser = .init()
        let dataMapper: RestaurantDataMapper = .init()
        let facilityType: FacilityType = .restaurant
        
        return .init(
            execute: { parkType in
                // キャッシュからの取得を試みる
                if let cachedRestaurants = try await cacheStore.get(
                    cacheKey(for: parkType),
                    as: [Restaurant].self
                ) {
                    request.logger.info("Using cached restaurant info for \(parkType.rawValue)")
                    return cachedRestaurants
                }
                
                request.logger.info("Fetching fresh restaurant data for \(parkType.rawValue)")
                
                do {
                    // APIから基本情報と運営状況を取得
                    async let basicInfoTask = try await apiFetcher.fetchBasicInfo(
                        parkType: parkType,
                        facilityType: facilityType,
                        parser: restaurantHTMLParser
                    )
                    
                    async let operatingStatusTask = try await apiFetcher.fetchOperatingStatus(
                        parkType: parkType,
                        facilityType: facilityType
                    )
                    
                    // 並行して取得した情報を待機
                    let (basicInfoList, operatingStatusList) = try await (basicInfoTask, operatingStatusTask)
                    
                    // データを統合
                    let restaurants = dataMapper.integrateRestaurantData(
                        basicInfoList: basicInfoList,
                        operatingStatusList: operatingStatusList
                    )
                    
                    // 統合データをキャッシュに保存
                    try await cacheStore.set(
                        cacheKey(for: parkType),
                        to: restaurants,
                        expiresIn: cacheExpirationTime
                    )
                    
                    return restaurants
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
