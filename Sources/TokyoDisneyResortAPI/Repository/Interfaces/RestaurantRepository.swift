//
//  RestaurantRepository.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/24.
//

import Vapor

struct RestaurantRepository {
    typealias T = Restaurant
    
    /// キャッシュを含めた最新の統合アトラクション情報を取得
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - request: HTTPリクエスト（キャッシュアクセスに使用）
    /// - Returns: 統合されたアトラクション情報
    var execute: @Sendable (_ parkType: ParkType, _ request: Request) async throws -> [Restaurant]
}
