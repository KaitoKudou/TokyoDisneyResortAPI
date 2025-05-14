//
//  Attraction.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

/// アトラクションの案内情報+基本情報を合わせた構造体
struct Attraction: Codable {
    let area: String
    let attractionName: String
    let iconTags: [String]
    let imageURL: String?
    let detailURL: String
    let standbyTime: StandbyTime?
    let operatingStatus: String?
    let dpaStatus: String?
    let fsStatus: String?
    let updateTime: String?
    let operatingHoursFrom: String?
    let operatingHoursTo: String?
    
    /// AttractionBasicInfoとAttractionOperatingStatusから新しいAttraction構造体を作成する
    init(basicInfo: AttractionBasicInfo, operatingStatus: AttractionOperatingStatus?) {
        self.area = basicInfo.area
        self.attractionName = basicInfo.name
        self.iconTags = basicInfo.iconTags
        self.imageURL = basicInfo.imageURL
        self.detailURL = basicInfo.detailURL
        
        // operatingStatusがnilの場合はnil値を設定
        self.standbyTime = operatingStatus?.standbyTime
        self.operatingStatus = operatingStatus?.operatingStatus
        self.dpaStatus = operatingStatus?.dpaStatus
        self.fsStatus = operatingStatus?.fsStatus
        self.updateTime = operatingStatus?.updateTime
        self.operatingHoursFrom = operatingStatus?.operatingHoursFrom
        self.operatingHoursTo = operatingStatus?.operatingHoursTo
    }
}
