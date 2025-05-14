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
    /// - Parameter urlSession: 通信に使用するURLセッション（デフォルトはshared）
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    /// アトラクション情報のHTMLを取得する
    /// - Parameter parkType: パークの種類（TDL/TDS）
    /// - Returns: HTML文字列
    /// - Throws: 通信エラーやデコードエラー
    func fetchAttractionHTML(parkType: ParkType) async throws -> String {
        let request = TokyoDisneyResortRequestBuilder(parkType: parkType).buildURLRequest()
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            // レスポンスのステータスコードをチェック
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            // HTMLへのデコード
            guard let htmlString = String(data: data, encoding: .utf8) else {
                throw APIError.decodingFailed
            }
            
            return htmlString
        } catch let urlError as URLError {
            throw APIError.networkError(urlError)
        } catch {
            throw APIError.unexpectedError(error)
        }
    }
    
    /// アトラクションの運営状況を取得する
    /// - Parameter parkType: パークの種類（TDL/TDS）
    /// - Returns: 運営状況のJSONデータ
    /// - Throws: 通信エラーやデコードエラー
    func fetchOperatingStatus(parkType: ParkType) async throws -> Data {
        // クライアントの設定
        var headers = HTTPHeaders()
        headers.add(name: "User-Agent", value: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15")
        headers.add(name: "Accept", value: "application/json")
        
        var request = URLRequest(url: URL(string: "https://www.tokyodisneyresort.jp/_/realtime/\(parkType.rawValue)_attraction.json")!)
        
        // 個別にヘッダーを設定
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            // レスポンスのステータスコードをチェック
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            
            return data
        } catch let urlError as URLError {
            throw APIError.networkError(urlError)
        } catch {
            throw APIError.unexpectedError(error)
        }
    }
}
