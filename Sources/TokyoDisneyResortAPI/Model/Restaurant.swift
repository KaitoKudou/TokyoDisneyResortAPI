//
//  Restaurant.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/19.
//

import Foundation

/// ディズニーリゾートのレストラン情報を表す構造体
struct Restaurant: Codable {
    // 基本情報（スクレイピングから取得）
    let area: String
    let name: String
    let iconTags: [String]
    let imageURL: String?
    let detailURL: String?
    let reservationURL: String?
    
    // 運営状況（APIから取得）
    let facilityID: String?
    let facilityName: String?
    let facilityStatus: String?
    let standbyTimeMin: StandbyTime?
    let standbyTimeMax: StandbyTime?
    let operatingHours: [OperatingHours]?
    let useStandbyTimeStyle: Bool?
    let updateTime: String?
    let popCornFlavor: String?
    
    /// 基本情報のみでの初期化（スクレイピング用）
    init(area: String,
         name: String,
         iconTags: [String],
         imageURL: String?,
         detailURL: String?,
         reservationURL: String?
    ) {
        self.area = area
        self.name = name
        self.iconTags = iconTags
        self.imageURL = imageURL
        self.detailURL = detailURL
        self.reservationURL = reservationURL
        
        // 以下はAPIから取得するのでnilに設定
        self.facilityID = nil
        self.facilityName = nil
        self.facilityStatus = nil
        self.standbyTimeMin = nil
        self.standbyTimeMax = nil
        self.operatingHours = nil
        self.useStandbyTimeStyle = nil
        self.updateTime = nil
        self.popCornFlavor = nil
    }
    
    /// 運営状況情報を含めた完全な初期化
    init(area: String,
         name: String,
         iconTags: [String],
         imageURL: String?,
         detailURL: String?,
         reservationURL: String?,
         facilityID: String?,
         facilityName: String? = nil,
         facilityStatus: String?,
         standbyTimeMin: StandbyTime?,
         standbyTimeMax: StandbyTime?,
         operatingHours: [OperatingHours]?,
         useStandbyTimeStyle: Bool?,
         updateTime: String?,
         popCornFlavor: String?
    ) {
        self.area = area
        self.name = name
        self.iconTags = iconTags
        self.imageURL = imageURL
        self.detailURL = detailURL
        self.reservationURL = reservationURL
        self.facilityID = facilityID
        self.facilityName = facilityName
        self.facilityStatus = facilityStatus
        self.standbyTimeMin = standbyTimeMin
        self.standbyTimeMax = standbyTimeMax
        self.operatingHours = operatingHours
        self.useStandbyTimeStyle = useStandbyTimeStyle
        self.updateTime = updateTime
        self.popCornFlavor = popCornFlavor
    }
    
    // デコーダーから初期化
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 基本情報のデコード（存在しない場合はデフォルト値を使用）
        area = try container.decodeIfPresent(String.self, forKey: .area) ?? "エリア不明"
        
        let decodedName = try container.decodeIfPresent(String.self, forKey: .name)
        let decodedFacilityName = try container.decodeIfPresent(String.self, forKey: .facilityName)
        
        // name: name が nil かつ facilityName が nil でなければ facilityName を使用、それ以外は name を使用
        name = (decodedName == nil && decodedFacilityName != nil) ? decodedFacilityName! : decodedName ?? "レストラン名不明"
        
        // その他の基本情報
        iconTags = try container.decodeIfPresent([String].self, forKey: .iconTags) ?? []
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        detailURL = try container.decodeIfPresent(String.self, forKey: .detailURL)
        reservationURL = try container.decodeIfPresent(String.self, forKey: .reservationURL)
        
        // API関連フィールド
        facilityID = try container.decodeIfPresent(String.self, forKey: .facilityID)
        facilityName = decodedFacilityName
        facilityStatus = try container.decodeIfPresent(String.self, forKey: .facilityStatus)
        standbyTimeMin = try container.decodeIfPresent(StandbyTime.self, forKey: .standbyTimeMin)
        standbyTimeMax = try container.decodeIfPresent(StandbyTime.self, forKey: .standbyTimeMax)
        operatingHours = try container.decodeIfPresent([OperatingHours].self, forKey: .operatingHours)
        useStandbyTimeStyle = try container.decodeIfPresent(Bool.self, forKey: .useStandbyTimeStyle)
        updateTime = try container.decodeIfPresent(String.self, forKey: .updateTime)
        popCornFlavor = try container.decodeIfPresent(String.self, forKey: .popCornFlavor)
    }
    
    private enum CodingKeys: String, CodingKey {
        // スクレイピングデータのキー（基本情報）
        case area
        case name
        case iconTags
        case imageURL
        case detailURL
        case reservationURL
        
        // APIデータのキー（運営状況）
        case facilityID = "FacilityID"
        case facilityName = "FacilityName"
        case facilityStatus = "FacilityStatus"
        case standbyTimeMin = "StandbyTimeMin"
        case standbyTimeMax = "StandbyTimeMax"
        case operatingHours = "operatingHours"
        case useStandbyTimeStyle = "UseStandbyTimeStyle"
        case updateTime = "UpdateTime"
        case popCornFlavor = "PopCornFlavors"
    }
    
    // operatingHours配列の各要素に対応する内部構造体
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
