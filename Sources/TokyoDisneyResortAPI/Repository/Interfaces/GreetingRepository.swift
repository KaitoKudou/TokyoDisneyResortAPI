//
//  GreetingRepository.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/18.
//

import Vapor

struct GreetingRepository {
    typealias T = Greeting
    
    /// キャッシュを含めた最新のグリーティング情報を取得
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - request: HTTPリクエスト（キャッシュアクセスに使用）
    /// - Returns: 統合されたグリーティング情報
    var execute: @Sendable (_ parkType: ParkType) async throws -> [Greeting]
}
