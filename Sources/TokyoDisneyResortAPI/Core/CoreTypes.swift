//
//  CoreTypes.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/24.
//

import Foundation

// パークタイプを表す列挙型
enum ParkType: String, Sendable {
    case tdl // 東京ディズニーランド
    case tds // 東京ディズニーシー
}

// 施設タイプを表す列挙型
enum FacilityType: String, Sendable {
    case attraction // アトラクション情報
    case greeting   // グリーティング情報
    case restaurant // レストラン情報
}
