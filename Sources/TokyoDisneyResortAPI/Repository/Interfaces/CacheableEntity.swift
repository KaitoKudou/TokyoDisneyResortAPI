//
//  CacheableEntity.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/18.
//

import Vapor
import Dependencies

/// キャッシュ可能なエンティティのためのプロトコル
/// - Note: キャッシュ設定（キャッシュキーと有効期限）を提供する
protocol CacheableEntity {
    /// 指定されたパークタイプに対するキャッシュキーを生成する
    /// - Parameter parkType: パークタイプ (TDL/TDS)
    /// - Returns: キャッシュキーの文字列
    static func cacheKey(for parkType: ParkType) -> String
    
    /// キャッシュの有効期限を返す
    /// - Returns: キャッシュの有効期限
    static var cacheExpirationTime: CacheExpirationTime { get }
}


