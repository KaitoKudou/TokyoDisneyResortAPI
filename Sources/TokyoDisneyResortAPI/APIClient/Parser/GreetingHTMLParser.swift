//
//  GreetingHTMLParser.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/16.
//

import SwiftSoup

/// HTML文書からグリーティング情報を抽出するパーサー
struct GreetingHTMLParser: Sendable {
    /// HTML文字列からグリーティング基本情報を抽出する
    /// - Parameter htmlString: 東京ディズニーリゾートのWebサイトから取得したHTML文字列
    /// - Returns: 抽出されたグリーティング基本情報
    /// - Throws: HTMLパースエラー
    func parseGreetings(from htmlString: String) throws -> [Greeting] {
        do {
            let document = try SwiftSoup.parse(htmlString)
            return try extractGreetings(from: document)
        } catch is Exception {
            throw HTMLParserError.parseError
        } catch {
            throw error
        }
    }
    
    /// HTML文書からグリーティング情報を抽出する
    private func extractGreetings(from document: Document) throws -> [Greeting] {
        var greetings = [Greeting]()
        
        // data-categorize属性を持つli要素を探す
        let greetingLiItems = try document.select("li[data-categorize]")
        
        if greetingLiItems.isEmpty() {
            throw HTMLParserError.noGreetingFound
        }
        
        // 各グリーティングの情報を解析
        for element in greetingLiItems {
            do {
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
                let greeting = Greeting(
                    area: area,
                    name: name,
                    character: cleanedCharacterName,
                    imageURL: imageURL,
                    detailURL: detailURL
                )
                
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
}
