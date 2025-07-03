//
//  APIError.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Foundation
import Vapor

/// APIクライアントが発生させる可能性のあるエラー
enum APIError: AbortError, CustomStringConvertible {
    case invalidResponse
    case decodingFailed
    case unexpectedError((any Error)?)
    case serverError(Int)
    case httpError(Int)
    
    /// エラーの説明を取得
    var description: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed:
            return "Failed to decode the response data"
        case .unexpectedError(let error):
            return "Unexpected error: \(error?.localizedDescription ?? "Unknown error")"
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
        case .unexpectedError:
            return .internalServerError
        case .serverError:
            return .badGateway
        case .httpError(let statusCode):
            return HTTPResponseStatus(statusCode: statusCode)
        }
    }
}
