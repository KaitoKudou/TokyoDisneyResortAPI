//
//  AttractionHTMLParser.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import SwiftSoup

/// HTML文書からアトラクション情報を抽出するパーサー
struct AttractionHTMLParser: FacilityHTMLParser, Sendable {
    typealias FacilityType = Attraction
    
    /// HTMLから抽出した要素をアトラクションモデルに変換する
    func createFacilityModel(from element: Element) throws -> FacilityType {
        // エリア名を取得
        let area = try element.select(".area").first()?.text() ?? "エリア不明"
        
        // アトラクション名を取得
        let name = try element.select(".heading3").first()?.text() ?? element.select("h3").first()?.text() ?? "名前不明"
        
        // 名前から"New"を除外し、空白を整理
        let cleanedName = name
            .replacingOccurrences(of: "NEW", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // アイコンタグを取得
        let iconTags = try element.select(".iconTag, .iconTag3").map { try $0.text() }
        
        // 画像URLを取得
        let imgElement = try element.select("img").first()
        let imageURL = try imgElement?.attr("src")
        
        // 詳細ページへのURLを取得
        let linkElement = try element.select("a").first()
        let detailURL = try linkElement?.attr("href") ?? "URL不明"
        
        // Attraction（基本情報のみ）を作成
        return Attraction(
            area: area,
            name: cleanedName,
            iconTags: iconTags,
            imageURL: imageURL,
            detailURL: detailURL
        )
    }
}
