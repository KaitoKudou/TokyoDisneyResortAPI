//
//  TokyoDisneyResortRequest.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Foundation

protocol TokyoDisneyResortRequest {
    /// APIのエンドポイントURL
    var baseURL: URL { get }
    
    // HTTPメソッド
    var method: String { get }
    
    // パークタイプ (tdl または tds)
    var parkType: ParkType { get }
    
    // 施設タイプ (アトラクションまたはグリーティング)
    var facilityType: FacilityType { get }
}

// パークタイプを表す列挙型
enum ParkType: String {
    case tdl // 東京ディズニーランド
    case tds // 東京ディズニーシー
}

// 施設タイプを表す列挙型
enum FacilityType: String {
    case attraction // アトラクション情報
    case greeting   // グリーティング情報
}

extension TokyoDisneyResortRequest {
    // パークタイプと施設タイプに応じたURLを生成
    var baseURL: URL {
        let urlString: String
        
        switch facilityType {
        case .attraction:
            // HTMLのエンドポイント（スクレイピング用）
            urlString = "https://www.tokyodisneyresort.jp/\(parkType.rawValue)/attraction.html"
            
        case .greeting:
            // グリーティング情報のJSONエンドポイント
            urlString = "https://www.tokyodisneyresort.jp/\(parkType.rawValue)/greeting.html"
        }
        
        // URLが無効な場合はfatalErrorを発生
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL: \(urlString)")
        }
        
        return url
    }
    
    // デフォルトのHTTPメソッド（GET）
    var method: String {
        return "GET"
    }
}
