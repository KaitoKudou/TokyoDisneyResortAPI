//
//  RepositoryProtocol.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/18.
//

import Vapor
import Dependencies

/// 施設リポジトリのための共通プロトコル
/// - Note: アトラクションとグリーティングのリポジトリで共通する機能を提供する
protocol RepositoryProtocol<T> {
    /// 施設情報の型
    associatedtype T: Codable & Sendable
    
    /// 施設タイプ（アトラクションまたはグリーティング）
    var facilityType: FacilityType { get }
    
    /// 指定されたパークタイプと施設種別に対するキャッシュキーを生成する
    /// - Parameter parkType: パークタイプ (TDL/TDS)
    /// - Returns: キャッシュキーの文字列
    func cacheKey(for parkType: ParkType) -> String
    
    /// キャッシュの有効期限を返す
    /// - Returns: キャッシュの有効期限
    var cacheExpirationTime: CacheExpirationTime { get }
}
