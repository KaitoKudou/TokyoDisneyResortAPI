//
//  AttractionRepository.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//  Updated by GitHub Copilot on 2025/06/19.
//

import Vapor

struct AttractionRepository: FacilityRepository {
    typealias T = Attraction
    
    /// 施設タイプ（アトラクション）
    let facilityType: FacilityType = .attraction
    
    /// キャッシュの有効期限（デフォルト：10分）
    let cacheExpirationTime: CacheExpirationTime = .minutes(10)
    
    /// 指定されたパークタイプのアトラクションキャッシュキーを生成
    /// - Parameter parkType: パークタイプ (TDL/TDS)
    /// - Returns: キャッシュキー
    func cacheKey(for parkType: ParkType) -> String {
        return "attractions_\(parkType.rawValue)"
    }
    
    /// キャッシュを含めた最新の統合アトラクション情報を取得
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - request: HTTPリクエスト（キャッシュアクセスに使用）
    /// - Returns: 統合されたアトラクション情報
    var execute: @Sendable (_ parkType: ParkType, _ request: Request) async throws -> [Attraction]
}
