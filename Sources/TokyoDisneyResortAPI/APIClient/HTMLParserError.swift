//
//  HTMLParserError.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Vapor

/// HTML パース処理で発生する可能性のあるエラー
enum HTMLParserError: Error, AbortError, CustomStringConvertible {
    case invalidHTML
    case parseError
    case networkError
    case noAttractionFound
    case noGreetingFound
    
    /// エラーの説明 (CustomStringConvertible)
    var description: String {
        switch self {
        case .invalidHTML:
            return "HTMLデータの形式が無効です"
        case .parseError:
            return "HTMLデータの解析中にエラーが発生しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .noAttractionFound:
            return "アトラクション情報が見つかりませんでした"
        case .noGreetingFound:
            return "グリーティング情報が見つかりませんでした"
        }
    }
    
    /// AbortError プロトコルへの準拠 - エラーに適切なHTTPステータスコードを関連付ける
    var status: HTTPResponseStatus {
        switch self {
        case .invalidHTML, .parseError:
            return .unprocessableEntity
        case .networkError:
            return .serviceUnavailable
        case .noAttractionFound, .noGreetingFound:
            return .notFound
        }
    }
    
    /// AbortError プロトコルへの準拠 - クライアントに送信するエラー理由
    var reason: String {
        return description
    }
}
