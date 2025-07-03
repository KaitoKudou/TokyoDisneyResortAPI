//
//  TokyoDisneyResortClient.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Vapor

/// 東京ディズニーリゾートのWebサイトやAPIと通信を行うクライアント
/// 通信処理のみを担当し、レスポンスデータの解析や変換は行わない
struct TokyoDisneyResortClient: Sendable {
    /// URLセッション
    private let urlSession: URLSession
    
    /// 初期化
    /// - Parameters:
    ///   - urlSession: 通信に使用するURLセッション（デフォルトはshared）
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    /// アトラクション情報のHTMLを取得する
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - facilityType: 施設の種類（デフォルトはアトラクション）
    /// - Returns: HTML文字列
    /// - Throws: 通信エラーやデコードエラー
    func fetchHTMLString(parkType: ParkType, facilityType: FacilityType) async throws -> String {
        let request = TokyoDisneyResortRequestBuilder(parkType: parkType, facilityType: facilityType).buildURLRequest()
        
        let (data, response) = try await urlSession.data(for: request)
        
        // レスポンスのステータスコードをチェック
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // ステータスコードの検証
        switch httpResponse.statusCode {
        case 200...299:
            // 成功
            break
        case 429:
            throw Abort(.tooManyRequests)
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // HTMLへのデコード
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw APIError.decodingFailed
        }
        
        return htmlString
    }
    
    /// 施設（アトラクションやグリーティング）の運営状況を取得する
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - facilityType: 施設の種類（アトラクションまたはグリーティング）
    /// - Returns: 運営状況のJSONデータ
    /// - Throws: 通信エラーやデコードエラー
    func fetchOperatingStatus(parkType: ParkType, facilityType: FacilityType) async throws -> Data {
        // リクエストビルダーを使用してリクエストの基本設定を取得
        let builder = TokyoDisneyResortRequestBuilder(parkType: parkType, facilityType: facilityType)
        let baseRequest = builder.buildURLRequest()
        
        // 施設の運営状況のJSONエンドポイントURL
        let jsonURL = URL(string: "https://www.tokyodisneyresort.jp/_/realtime/\(parkType.rawValue)_\(facilityType.rawValue).json")!
        
        // JSONエンドポイントへのリクエスト
        var request = URLRequest(url: jsonURL)
        
        // ベースリクエストからヘッダーを引き継ぐ
        baseRequest.allHTTPHeaderFields?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // JSONを明示的に要求するヘッダーを設定
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await urlSession.data(for: request)
        
        // レスポンスのステータスコードをチェック
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // ステータスコードの検証
        switch httpResponse.statusCode {
        case 200...299:
            // 成功
            break
        case 429:
            throw Abort(.tooManyRequests)
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return data
    }
}
