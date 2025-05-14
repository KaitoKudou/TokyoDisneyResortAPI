//
//  AttractionHTMLParser.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import SwiftSoup

/// HTML文書からアトラクション情報を抽出するパーサー
struct AttractionHTMLParser: Sendable {
    /// HTML文字列からアトラクション基本情報を抽出する
    /// - Parameter htmlString: 東京ディズニーリゾートのWebサイトから取得したHTML文字列
    /// - Returns: 抽出されたアトラクション基本情報
    /// - Throws: HTMLパースエラー
    func parseAttractions(from htmlString: String) throws -> [AttractionBasicInfo] {
        do {
            let document = try SwiftSoup.parse(htmlString)
            return try extractAttractions(from: document)
        } catch is Exception {
            throw HTMLParserError.parseError
        } catch {
            throw error
        }
    }
    
    /// HTML文書からアトラクション情報を抽出する
    private func extractAttractions(from document: Document) throws -> [AttractionBasicInfo] {
        var attractions = [AttractionBasicInfo]()
        
        // data-categorize属性を持つli要素を探す
        let attractionLiItems = try document.select("li[data-categorize]")
        
        if attractionLiItems.isEmpty() {
            throw HTMLParserError.noAttractionFound
        }
        
        // 各アトラクションの情報を解析
        for element in attractionLiItems {
            do {
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
                
                // AttractionBasicInfoを作成
                let attraction = AttractionBasicInfo(
                    area: area,
                    name: cleanedName,
                    iconTags: iconTags,
                    imageURL: imageURL,
                    detailURL: detailURL
                )
                
                attractions.append(attraction)
            } catch {
                // 1つのアトラクション解析に失敗してもその他は続行する
                continue
            }
        }
        
        if attractions.isEmpty {
            throw HTMLParserError.parseError
        }
        
        return attractions
    }
}
