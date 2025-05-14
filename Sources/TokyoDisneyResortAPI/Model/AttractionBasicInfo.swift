//
//  AttractionBasicInfo.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

/// アトラクションの基本情報を表す構造体
struct AttractionBasicInfo: Codable {
    let area: String
    let name: String
    let iconTags: [String]
    let imageURL: String?
    let detailURL: String
}
