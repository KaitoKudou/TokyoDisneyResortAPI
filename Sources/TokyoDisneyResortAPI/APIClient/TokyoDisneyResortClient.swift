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
    
    /// リトライ回数の最大値
    private let maxRetries: Int
    
    /// リトライ間の遅延（秒）
    private let retryDelay: TimeInterval
    
    /// 初期化
    /// - Parameters:
    ///   - urlSession: 通信に使用するURLセッション（デフォルトはshared）
    ///   - maxRetries: リトライ回数の最大値（デフォルトは3回）
    ///   - retryDelay: リトライ間の遅延（秒、デフォルトは1秒）
    init(
        urlSession: URLSession = .shared,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.urlSession = urlSession
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    /// アトラクション情報のHTMLを取得する
    /// - Parameters:
    ///   - parkType: パークの種類（TDL/TDS）
    ///   - facilityType: 施設の種類（デフォルトはアトラクション）
    /// - Returns: HTML文字列
    /// - Throws: 通信エラーやデコードエラー
    func fetchHTMLString(parkType: ParkType, facilityType: FacilityType) async throws -> String {
        let request = TokyoDisneyResortRequestBuilder(parkType: parkType, facilityType: facilityType).buildURLRequest()
        
        // リトライを許容して実行
        return try await withRetries { attempt in
            do {
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
                    // レートリミット - リトライ
                    if attempt < maxRetries {
                        throw APIError.rateLimited
                    } else {
                        throw APIError.tooManyRequests
                    }
                case 500...599:
                    // サーバーエラー - リトライ
                    if attempt < maxRetries {
                        throw APIError.serverError(httpResponse.statusCode)
                    } else {
                        throw APIError.serverError(httpResponse.statusCode)
                    }
                default:
                    throw APIError.httpError(httpResponse.statusCode)
                }
                
                // HTMLへのデコード
                guard let htmlString = String(data: data, encoding: .utf8) else {
                    throw APIError.decodingFailed
                }
                
                return htmlString
            } catch let urlError as URLError {
                // ネットワークエラー - 接続エラーのみリトライ
                if [URLError.notConnectedToInternet, URLError.networkConnectionLost].contains(urlError.code),
                   attempt < maxRetries {
                    throw APIError.networkError(urlError)
                } else {
                    throw APIError.networkError(urlError)
                }
            } catch {
                throw error
            }
        }
    }
    
    /// 指定された関数をリトライロジック付きで実行する
    /// - Parameter operation: 実行する非同期操作
    /// - Returns: 操作の結果
    private func withRetries<T>(operation: @escaping (_ attempt: Int) async throws -> T) async throws -> T {
        var lastError: (any Error)?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation(attempt)
            } catch let error as APIError where error.isRetryable {
                lastError = error
                // 遅延を指数関数的に増加（バックオフ）
                let delay = retryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            } catch {
                // リトライ不可のエラー
                throw error
            }
        }
        
        // 最後のエラーを投げる
        throw lastError ?? APIError.unexpectedError(nil)
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
        
        // リトライを許容して実行
        return try await withRetries { attempt in
            do {
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
                    // レートリミット - リトライ
                    throw APIError.rateLimited
                case 500...599:
                    // サーバーエラー - リトライ
                    throw APIError.serverError(httpResponse.statusCode)
                default:
                    throw APIError.httpError(httpResponse.statusCode)
                }
                
                return data
            } catch let urlError as URLError {
                // ネットワークエラー
                throw APIError.networkError(urlError)
            } catch {
                throw error
            }
        }
    }
}
