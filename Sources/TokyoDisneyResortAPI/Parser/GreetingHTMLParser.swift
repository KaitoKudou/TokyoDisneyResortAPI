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
    
    /// HTMLから抽出した要素をグリーティングモデルに変換する
    func createFacilityModel(from element: Element) throws -> FacilityType {
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
