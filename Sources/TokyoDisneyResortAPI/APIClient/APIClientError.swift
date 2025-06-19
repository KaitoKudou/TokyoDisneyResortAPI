//
//  APIClientError.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Foundation
import Vapor

/// APIクライアントが発生させる可能性のあるエラー
enum APIError: Error, AbortError, CustomStringConvertible {
    case invalidResponse
    case decodingFailed
    case networkError(URLError)
    case unexpectedError((any Error)?)
    case rateLimited
    case tooManyRequests
    case serverError(Int)
    case httpError(Int)
    
    /// エラーの説明を取得
    var description: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed:
            return "Failed to decode the response data"
        case .networkError(let urlError):
            return "Network error: \(urlError.localizedDescription)"
        case .unexpectedError(let error):
            return "Unexpected error: \(error?.localizedDescription ?? "Unknown error")"
        case .rateLimited:
            return "Request was rate limited"
        case .tooManyRequests:
            return "Too many requests"
        case .serverError(let statusCode):
            return "Server error with status code \(statusCode)"
        case .httpError(let statusCode):
            return "HTTP error with status code \(statusCode)"
        }
    }
    
    /// AbortError プロトコルへの準拠 - エラーに適切なHTTPステータスコードを関連付ける
    var status: HTTPResponseStatus {
        switch self {
        case .invalidResponse:
            return .badGateway
        case .decodingFailed:
            return .unprocessableEntity
        case .networkError:
            return .serviceUnavailable
        case .unexpectedError:
            return .internalServerError
        case .rateLimited, .tooManyRequests:
            return .tooManyRequests
        case .serverError:
            return .badGateway
        case .httpError(let statusCode):
            return HTTPResponseStatus(statusCode: statusCode)
        }
    }
    
    /// AbortError プロトコルへの準拠 - クライアントに送信するエラー理由
    var reason: String {
        return description
    }
}
