//
//  HTMLParserError.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Vapor

/// HTML パース処理で発生する可能性のあるエラー
enum HTMLParserError: AbortError, CustomStringConvertible {
    case invalidHTML
    case parseError
    case noAttractionFound
    case noGreetingFound
    case noRestaurantFound
    
    /// エラーの説明 (CustomStringConvertible)
    var description: String {
        switch self {
        case .invalidHTML:
            return "HTMLデータの形式が無効です"
        case .parseError:
            return "HTMLデータの解析中にエラーが発生しました"
        case .noAttractionFound:
            return "アトラクション情報が見つかりませんでした"
        case .noGreetingFound:
            return "グリーティング情報が見つかりませんでした"
        case .noRestaurantFound:
            return "レストラン情報が見つかりませんでした"
        }
    }
    
    /// AbortError プロトコルへの準拠 - エラーに適切なHTTPステータスコードを関連付ける
    var status: HTTPResponseStatus {
        switch self {
        case .invalidHTML, .parseError:
            return .unprocessableEntity
        case .noAttractionFound, .noGreetingFound, .noRestaurantFound:
            return .notFound
        }
    }
}
