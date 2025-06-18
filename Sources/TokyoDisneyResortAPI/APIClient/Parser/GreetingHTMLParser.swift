//
//  GreetingHTMLParser.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/16.
//

import SwiftSoup

/// HTML文書からグリーティング情報を抽出するパーサー
struct GreetingHTMLParser: FacilityHTMLParser, Sendable {
    typealias FacilityType = Greeting
    
    /// 既存コードとの互換性のために残すメソッド
    func parseGreetings(from htmlString: String) throws -> [Greeting] {
        return try parseFacilities(from: htmlString)
    }
    
    /// HTML文書からグリーティング情報を抽出する
    func extractFacilities(from document: Document) throws -> [Greeting] {
        // FacilityHTMLParserのデフォルト実装を利用するが、エラー型をカスタマイズ
        var greetings = [Greeting]()
        
        // data-categorize属性を持つli要素を探す
        let greetingLiItems = try document.select("li[data-categorize]")
        
        if greetingLiItems.isEmpty() {
            throw HTMLParserError.noGreetingFound // グリーティング用のエラー
        }
        
        // 各グリーティングの情報を解析
        for element in greetingLiItems {
            do {
                let greeting = try createFacilityModel(from: element)
                greetings.append(greeting)
            } catch {
                // 1つのグリーティング解析に失敗してもその他は続行する
                continue
            }
        }
        
        if greetings.isEmpty {
            throw HTMLParserError.parseError
        }
        
        return greetings
    }
    
    /// HTMLから抽出した要素をグリーティングモデルに変換する
    func createFacilityModel(from element: Element) throws -> Greeting {
        // エリア名を取得
        let area = try element.select(".area").first()?.text() ?? "エリア不明"
        
        // グリーティング名を取得
        let name = try element.select(".heading3").first()?.text() ?? element.select("h3").first()?.text() ?? "名前不明"
        
        // キャラクター名を取得
        let character = try element.select(".sponser").first()?.text() ?? "キャラクター不明"
        
        // 名前から"New"を除外し、空白を整理
        let cleanedCharacterName = character
            .replacingOccurrences(of: "キャラクター：", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 画像URLを取得
        let imgElement = try element.select("img").first()
        let imageURL = try imgElement?.attr("src")
        
        // 詳細ページへのURLを取得
        let linkElement = try element.select("a").first()
        let detailURL = try linkElement?.attr("href")
        
        // Greeting（基本情報のみ）を作成 - スクレイピング用のinitを使用
        return Greeting(
            area: area,
            name: name,
            character: cleanedCharacterName,
            imageURL: imageURL,
            detailURL: detailURL
        )
    }
}
