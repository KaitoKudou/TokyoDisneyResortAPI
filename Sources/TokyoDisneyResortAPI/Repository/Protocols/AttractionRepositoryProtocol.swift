//
//  AttractionRepositoryProtocol.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Vapor

/// アトラクション情報の取得を担当するリポジトリのプロトコル
protocol AttractionRepositoryProtocol: Sendable {
    /// キャッシュを含めた最新の統合アトラクション情報を取得
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - request: HTTPリクエスト（キャッシュアクセスに使用）
    /// - Returns: 統合されたアトラクション情報
    func getIntegratedAttractionInfo(parkType: ParkType, request: Request) async throws -> [Attraction]
}
