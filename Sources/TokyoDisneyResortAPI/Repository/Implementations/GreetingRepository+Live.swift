//
//  GreetingRepository+Live.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/18.
//  Updated by GitHub Copilot on 2025/06/19.
//

import Dependencies
import Foundation
import Vapor

extension GreetingRepository: DependencyKey {
    static var liveValue: Self {
        @Dependency(\.cacheStore) var cacheStore
        
        let apiFetcher = APIFetcher<Greeting>()
        let greetingHTMLParser: GreetingHTMLParser = .init()
        let greetingDataMapper: GreetingDataMapper = .init()
        
        // FacilityRepository プロトコルの実装
        let facilityType: FacilityType = .greeting
        let cacheExpirationTime: CacheExpirationTime = .minutes(10)
        
        @Sendable func cacheKey(for parkType: ParkType) -> String {
            return "greetings_\(parkType.rawValue)"
        }
        
        return .init(
            execute: { parkType, request in
                // キャッシュからの取得を試みる
                if let cachedGreetings = try await cacheStore.get(
                    cacheKey(for: parkType), 
                    as: [Greeting].self, 
                    request: request
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
                        facilityType: facilityType,
                        request: request
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
                        expiresIn: cacheExpirationTime,
                        request: request
                    )
                    
                    return greetings
                } catch {
                    request.logger.error("Failed to fetch greeting data: \(error.localizedDescription)")
                    throw error
                }
            }
        )
    }
}
