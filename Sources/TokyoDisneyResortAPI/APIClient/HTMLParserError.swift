//
//  HTMLParserError.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

/// HTML パース処理で発生する可能性のあるエラー
enum HTMLParserError: Error {
    case invalidHTML
    case parseError
    case networkError
    case noAttractionFound
    
    var localizedDescription: String {
        switch self {
        case .invalidHTML:
            return "HTMLデータの形式が無効です"
        case .parseError:
            return "HTMLデータの解析中にエラーが発生しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .noAttractionFound:
            return "アトラクション情報が見つかりませんでした"
        }
    }
}
