//
//  RestaurantHTMLParser.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/23.
//

import SwiftSoup

/// HTML文書からレストラン情報を抽出するパーサー
struct RestaurantHTMLParser: FacilityHTMLParser, Sendable {
    typealias FacilityType = Restaurant
    
    func createFacilityModel(from element: Element) throws -> FacilityType {
        // エリア名を取得
        let area = try element.select(".area").first()?.text() ?? "エリア不明"
        
        // レストラン名を取得
        let name = try element.select(".heading3").first()?.text() ?? element.select("h3").first()?.text() ?? "名前不明"
        
        // アイコンタグを取得
        let iconTags = try element.select(".iconTag, .iconTag3").map { try $0.text() }
        
        // 画像URLを取得
        let imgElement = try element.select("img").first()
        let imageURL = try imgElement?.attr("src")
        
        // 詳細ページへのURLを取得
        let linkElement = try element.select("a").first()
        let detailURL = try linkElement?.attr("href")
        
        // オンライン予約リンクを取得
        let reservationLinkElement = try element.select("div.button.conversion a").first()
        let reservationURL = try reservationLinkElement?.attr("href")
        
        return Restaurant(
            area: area,
            name: name,
            iconTags: iconTags,
            imageURL: imageURL,
            detailURL: detailURL,
            reservationURL: reservationURL
        )
        
    }
}
