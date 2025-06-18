//
//  APIClientError.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Foundation

/// APIクライアントが発生させる可能性のあるエラー
enum APIError: Error {
    case invalidResponse
    case decodingFailed
    case networkError(URLError)
    case unexpectedError((any Error)?)
    case rateLimited
    case tooManyRequests
    case serverError(Int)
    case httpError(Int)
    
    /// このエラーがリトライ可能かどうか
    var isRetryable: Bool {
        switch self {
        case .networkError(let urlError):
            // 一時的なネットワークエラーのみリトライ
            return [URLError.notConnectedToInternet, 
                    URLError.networkConnectionLost,
                    URLError.timedOut].contains(urlError.code)
        case .rateLimited, .serverError:
            // レートリミットやサーバーエラーはリトライ
            return true
        default:
            // その他はリトライしない
            return false
        }
    }
}
