//
//  Greeting.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/15.
//

import Foundation

/// ディズニーリゾートのグリーティング情報を表す構造体
struct Greeting: Codable {
    // 基本情報（スクレイピングから取得）
    let area: String
    let name: String
    let character: String
    var imageURL: String?
    var detailURL: String?
    
    
    // 基本情報（APIから取得）
    let facilityID: String?
    let facilityName: String?
    let facilityStatus: String?
    let standbyTime: StandbyTime?
    let operatingHours: [OperatingHours]?
    let useStandbyTimeStyle: Bool?
    let updateTime: String?
    
    /// 基本情報のみでの初期化（スクレイピング用）
    init(area: String,
         name: String,
         character: String,
         imageURL: String?,
         detailURL: String?
    ) {
        self.area = area
        self.name = name
        self.character = character
        self.imageURL = imageURL
        self.detailURL = detailURL
        
        // 以下はAPIから取得するのでnilに設定
        self.facilityID = nil
        self.facilityName = nil
        self.facilityStatus = nil
        self.standbyTime = nil
        self.operatingHours = nil
        self.useStandbyTimeStyle = nil
        self.updateTime = nil
    }
    
    /// 運営状況情報を含めた完全な初期化
    init(area: String,
         name: String,
         character: String,
         imageURL: String?,
         detailURL: String?,
         facilityID: String?,
         facilityName: String?,
         facilityStatus: String?,
         standbyTime: StandbyTime?,
         operatingHours: [OperatingHours]?,
         useStandbyTimeStyle: Bool?,
         updateTime: String?
    ) {
        self.area = area
        self.name = name
        self.character = character
        self.imageURL = imageURL
        self.detailURL = detailURL
        self.facilityID = facilityID
        self.facilityName = facilityName
        self.facilityStatus = facilityStatus
        self.standbyTime = standbyTime
        self.operatingHours = operatingHours
        self.useStandbyTimeStyle = useStandbyTimeStyle
        self.updateTime = updateTime
    }
    
    // デコーダーからの初期化
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        area = try container.decodeIfPresent(String.self, forKey: .area) ?? "エリア不明"
        let decodedName = try container.decodeIfPresent(String.self, forKey: .name)
        let decodedFacilityName = try container.decodeIfPresent(String.self, forKey: .facilityName)
        
        // name: name が nil かつ facilityName が nil でなければ facilityName を使用、それ以外は name を使用
        name = (decodedName == nil && decodedFacilityName != nil) ? decodedFacilityName! : decodedName ?? "グリーティング名不明"
        character = try container.decodeIfPresent(String.self, forKey: .character) ?? "キャラクター不明"
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        detailURL = try container.decodeIfPresent(String.self, forKey: .detailURL) ?? ""
        
        // 基本情報のデコード
        facilityID = try container.decodeIfPresent(String.self, forKey: .facilityID)
        facilityName = try container.decodeIfPresent(String.self, forKey: .facilityName)
        facilityStatus = try container.decodeIfPresent(String.self, forKey: .facilityStatus)
        standbyTime = try container.decodeIfPresent(StandbyTime.self, forKey: .standbyTime)
        operatingHours = try container.decodeIfPresent([OperatingHours].self, forKey: .operatingHours)
        useStandbyTimeStyle = try container.decodeIfPresent(Bool.self, forKey: .useStandbyTimeStyle)
        updateTime = try container.decodeIfPresent(String.self, forKey: .updateTime)
    }
    
    // エンコーダーへの出力
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(area, forKey: .area)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(character, forKey: .character)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(detailURL, forKey: .detailURL)
        try container.encodeIfPresent(facilityID, forKey: .facilityID)
        try container.encodeIfPresent(facilityName, forKey: .facilityName)
        try container.encodeIfPresent(facilityStatus, forKey: .facilityStatus)
        try container.encodeIfPresent(standbyTime, forKey: .standbyTime)
        try container.encodeIfPresent(operatingHours, forKey: .operatingHours)
        try container.encodeIfPresent(useStandbyTimeStyle, forKey: .useStandbyTimeStyle)
        try container.encodeIfPresent(updateTime, forKey: .updateTime)
    }
    
    private enum CodingKeys: String, CodingKey {
        // スクレイピングデータのキー（基本情報）
        case area
        case name
        case character
        case imageURL
        case detailURL
        
        // APIデータのキー（運営状況）
        case facilityID = "FacilityID"
        case facilityName = "FacilityName"
        case facilityStatus = "FacilityStatus"
        case standbyTime = "StandbyTime"
        case operatingHours = "operatinghours"
        case useStandbyTimeStyle = "UseStandbyTimeStyle"
        case updateTime = "UpdateTime"
    }
    
    // operatinghours配列の各要素に対応する内部構造体
    struct OperatingHours: Codable {
        let operatingHoursFrom: String
        let operatingHoursTo: String
        let operatingStatus: String?
        
        private enum CodingKeys: String, CodingKey {
            case operatingHoursFrom = "OperatingHoursFrom"
            case operatingHoursTo = "OperatingHoursTo"
            case operatingStatus = "OperatingStatus"
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            operatingHoursFrom = try container.decode(String.self, forKey: .operatingHoursFrom)
            operatingHoursTo = try container.decode(String.self, forKey: .operatingHoursTo)
            operatingStatus = try container.decodeIfPresent(String.self, forKey: .operatingStatus)
        }
        
        /// 標準の初期化子
        init(operatingHoursFrom: String, operatingHoursTo: String, operatingStatus: String?) {
            self.operatingHoursFrom = operatingHoursFrom
            self.operatingHoursTo = operatingHoursTo
            self.operatingStatus = operatingStatus
        }
    }
}

/// グリーティング情報のAPIレスポンス形式に対応する構造体
struct GreetingResponse: Codable {
    /// エリアIDをキーとしてエリア情報を保持する辞書
    let areas: [String: AreaInfo]
    
    /// グリーティングの配列に変換する計算プロパティ
    var facilities: [Greeting] {
        var result: [Greeting] = []
        
        // 全エリアを走査
        for (_, areaInfo) in areas {
            // 各エリアの施設リストを走査
            if let facilities = areaInfo.facility {
                for facility in facilities {
                    // グリーティング情報があれば追加
                    if let greeting = facility.greeting {
                        result.append(greeting)
                    }
                }
            }
        }
        
        return result
    }
    
    /// デコード方法をカスタマイズする
    init(from decoder: any Decoder) throws {
        // トップレベルは辞書形式 (IDをキーとしたエリア情報)
        let container = try decoder.singleValueContainer()
        areas = try container.decode([String: AreaInfo].self)
    }
}

/// エリア情報を格納する構造体
struct AreaInfo: Codable {
    /// 施設のリスト
    let facility: [FacilityContainer]?
    
    enum CodingKeys: String, CodingKey {
        case facility = "Facility"
    }
}

/// 施設情報のコンテナ（グリーティングを含む）
struct FacilityContainer: Codable {
    /// グリーティング情報
    let greeting: Greeting?
}
