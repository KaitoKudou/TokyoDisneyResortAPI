//
//  AttractionRepository.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Vapor

struct AttractionRepository {
    /// キャッシュを含めた最新の統合アトラクション情報を取得
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - request: HTTPリクエスト（キャッシュアクセスに使用）
    /// - Returns: 統合されたアトラクション情報
    var getIntegratedAttractionInfo: @Sendable (_ parkType: ParkType, _ request: Request) async throws -> [Attraction]
    
    /// グリーティング情報を取得
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - request: HTTPリクエスト（キャッシュアクセスに使用）
    /// - Returns: グリーティング情報
    var getGreetingInfo: @Sendable (_ parkType: ParkType, _ request: Request) async throws -> [Greeting]
}

