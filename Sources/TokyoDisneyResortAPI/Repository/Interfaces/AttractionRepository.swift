//
//  AttractionRepository.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

struct AttractionRepository {
    typealias T = Attraction
    
    /// キャッシュを含めた最新の統合アトラクション情報を取得
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - request: HTTPリクエスト（キャッシュアクセスに使用）
    /// - Returns: 統合されたアトラクション情報
    var execute: @Sendable (_ parkType: ParkType) async throws -> [Attraction]
}
