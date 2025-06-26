//
//  AttractionHTMLParser.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import SwiftSoup

/// HTML文書からアトラクション情報を抽出するパーサー
struct AttractionHTMLParser: FacilityHTMLParser, Sendable {
//    typealias FacilityType = Attraction
//    
//    /// 既存コードとの互換性のために残すメソッド
//    func parseAttractions(from htmlString: String) throws -> [Attraction] {
//        return try parseFacilities(from: htmlString)
//    }
//    
//    /// HTML文書からアトラクション情報を抽出する
//    func extractFacilities(from document: Document) throws -> [Attraction] {
//        // FacilityHTMLParserのデフォルト実装を利用するが、エラー型をカスタマイズ
//        var attractions = [Attraction]()
//        
//        // data-categorize属性を持つli要素を探す
//        let attractionLiItems = try document.select("li[data-categorize]")
//        
//        if attractionLiItems.isEmpty() {
//            throw HTMLParserError.noAttractionFound // アトラクション用のエラー
//        }
//        
//        // 各アトラクションの情報を解析
//        for element in attractionLiItems {
//            do {
//                let attraction = try createFacilityModel(from: element)
//                attractions.append(attraction)
//            } catch {
//                // 1つのアトラクション解析に失敗してもその他は続行する
//                continue
//            }
//        }
//        
//        if attractions.isEmpty {
//            throw HTMLParserError.parseError
//        }
//        
//        return attractions
//    }
    
    /// HTMLから抽出した要素をアトラクションモデルに変換する
    func createFacilityModel(from element: Element) throws -> Attraction {
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
