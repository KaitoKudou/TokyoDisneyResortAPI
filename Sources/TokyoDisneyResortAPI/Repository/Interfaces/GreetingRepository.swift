//
//  GreetingRepository.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/18.
//

import Vapor

struct GreetingRepository: RepositoryProtocol {
    typealias T = Greeting
    
    /// 施設タイプ（グリーティング）
    let facilityType: FacilityType = .greeting
    
    /// キャッシュの有効期限（デフォルト：10分）
    let cacheExpirationTime: CacheExpirationTime = .minutes(10)
    
    /// 指定されたパークタイプのグリーティングキャッシュキーを生成
    /// - Parameter parkType: パークタイプ (TDL/TDS)
    /// - Returns: キャッシュキー
    func cacheKey(for parkType: ParkType) -> String {
        return "greetings_\(parkType.rawValue)"
    }
    
    /// キャッシュを含めた最新のグリーティング情報を取得
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - request: HTTPリクエスト（キャッシュアクセスに使用）
    /// - Returns: 統合されたグリーティング情報
    var execute: @Sendable (_ parkType: ParkType, _ request: Request) async throws -> [Greeting]
}
