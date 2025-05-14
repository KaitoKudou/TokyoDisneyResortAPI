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
    case unexpectedError(any Error)
}
