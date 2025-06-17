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
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - facilityType: 施設の種類（デフォルトはアトラクション）
    /// - Returns: HTML文字列
    /// - Throws: 通信エラーやデコードエラー
    func fetchAttractionHTML(parkType: ParkType, facilityType: FacilityType) async throws -> String {
        let request = TokyoDisneyResortRequestBuilder(parkType: parkType, facilityType: facilityType).buildURLRequest()
        
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
    
    /// 施設（アトラクションやグリーティング）の運営状況を取得する
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - facilityType: 施設の種類（アトラクションまたはグリーティング）
    /// - Returns: 運営状況のJSONデータ
    /// - Throws: 通信エラーやデコードエラー
    func fetchOperatingStatus(parkType: ParkType, facilityType: FacilityType) async throws -> Data {
        // アトラクションの場合は、専用のJSONエンドポイントを使用
        // リクエストビルダーを使用してリクエストの基本設定を取得
        let builder = TokyoDisneyResortRequestBuilder(parkType: parkType, facilityType: facilityType)
        let baseRequest = builder.buildURLRequest()
        
        // アトラクションの運営状況のJSONエンドポイントURL
        let jsonURL = URL(string: "https://www.tokyodisneyresort.jp/_/realtime/\(parkType.rawValue)_\(facilityType.rawValue).json")!
        
        // JSONエンドポイントへのリクエスト
        var request = URLRequest(url: jsonURL)
        
        // ベースリクエストからヘッダーを引き継ぐ
        baseRequest.allHTTPHeaderFields?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // JSONを明示的に要求するヘッダーを設定
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
