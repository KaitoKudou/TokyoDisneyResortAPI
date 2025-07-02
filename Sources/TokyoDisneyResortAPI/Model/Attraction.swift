// Attraction.swift
//  TokyoDisneyResortAPI
//  Created by 工藤 海斗 on 2025/05/05.

///ディズニーリゾートのアトラクション情報を表す構造体
struct Attraction: Codable {
    // 基本情報（スクレイピングから取得）
    let area: String
    let name: String
    let iconTags: [String]
    let imageURL: String?
    let detailURL: String
    
    // 運営状況（APIから取得）
    let facilityID: String?
    let facilityName: String?
    let facilityStatus: String?
    let standbyTime: StandbyTime?
    let operatingStatus: String?
    let dpaStatus: String?
    let fsStatus: String?
    let updateTime: String?
    let operatingHoursFrom: String?
    let operatingHoursTo: String?
    
    /// 基本情報のみでの初期化（スクレイピング用）
    init(area: String, name: String, iconTags: [String], imageURL: String?, detailURL: String) {
        self.area = area
        self.name = name
        self.iconTags = iconTags
        self.imageURL = imageURL
        self.detailURL = detailURL
        
        // 以下は API から取得するので運営状況は nil
        self.facilityID = nil
        self.facilityName = nil
        self.facilityStatus = nil
        self.standbyTime = nil
        self.operatingStatus = nil
        self.dpaStatus = nil
        self.fsStatus = nil
        self.updateTime = nil
        self.operatingHoursFrom = nil
        self.operatingHoursTo = nil
    }
    
    /// 運営状況情報を含めた完全な初期化
    init(
        area: String,
        name: String,
        iconTags: [String],
        imageURL: String?,
        detailURL: String,
        facilityID: String? = nil,
        facilityName: String? = nil,
        facilityStatus: String? = nil,
        standbyTime: StandbyTime? = nil,
        operatingStatus: String? = nil,
        dpaStatus: String? = nil,
        fsStatus: String? = nil,
        updateTime: String? = nil,
        operatingHoursFrom: String? = nil,
        operatingHoursTo: String? = nil,
    ) {
        self.area = area
        self.name = name
        self.iconTags = iconTags
        self.imageURL = imageURL
        self.detailURL = detailURL
        self.facilityID = facilityID
        self.facilityName = facilityName
        self.facilityStatus = facilityStatus
        self.standbyTime = standbyTime
        self.operatingStatus = operatingStatus
        self.dpaStatus = dpaStatus
        self.fsStatus = fsStatus
        self.updateTime = updateTime
        self.operatingHoursFrom = operatingHoursFrom
        self.operatingHoursTo = operatingHoursTo
    }
    
    // デコーダーからの初期化
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        area = try container.decodeIfPresent(String.self, forKey: .area) ?? "エリア不明"
        let decodedName = try container.decodeIfPresent(String.self, forKey: .name)
        let decodedFacilityName = try container.decodeIfPresent(String.self, forKey: .facilityName)
        
        // name: name が nil かつ facilityName が nil でなければ facilityName を使用、それ以外は name を使用
        name = (decodedName == nil && decodedFacilityName != nil) ? decodedFacilityName! : decodedName ?? "アトラクション名不明"
        
        iconTags = try container.decodeIfPresent([String].self, forKey: .iconTags) ?? []
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        detailURL = try container.decodeIfPresent(String.self, forKey: .detailURL) ?? ""
        
        facilityID = try container.decodeIfPresent(String.self, forKey: .facilityID)
        facilityName = decodedFacilityName
        facilityStatus = try container.decodeIfPresent(String.self, forKey: .facilityStatus)
        standbyTime = try container.decodeIfPresent(StandbyTime.self, forKey: .standbyTime)
        operatingStatus = try container.decodeIfPresent(String.self, forKey: .operatingStatus)
        dpaStatus = try container.decodeIfPresent(String.self, forKey: .dpaStatus)
        fsStatus = try container.decodeIfPresent(String.self, forKey: .fsStatus)
        updateTime = try container.decodeIfPresent(String.self, forKey: .updateTime)
        operatingHoursFrom = try container.decodeIfPresent(String.self, forKey: .operatingHoursFrom)
        operatingHoursTo = try container.decodeIfPresent(String.self, forKey: .operatingHoursTo)
    }
    
    private enum CodingKeys: String, CodingKey {
        // スクレイピングデータのキー（基本情報）
        case area
        case name
        case iconTags
        case imageURL
        case detailURL
        
        // APIデータのキー（運営状況）
        case facilityID = "FacilityID"
        case facilityName = "FacilityName"
        case facilityStatus = "FacilityStatus"
        case standbyTime = "StandbyTime"
        case operatingStatus = "OperatingStatus"
        case dpaStatus = "DpaStatus"
        case fsStatus = "FsStatus"
        case updateTime = "UpdateTime"
        case operatingHoursFrom = "OperatingHoursFrom"
        case operatingHoursTo = "OperatingHoursTo"
    }
}

// String型とBool型とInt型を受け付けるためのカスタムタイプ
enum StandbyTime: Codable, Equatable {
    case string(String)
    case boolean(Bool)
    case integer(Int)
    
    static func == (lhs: StandbyTime, rhs: StandbyTime) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lValue), .string(let rValue)):
            return lValue == rValue
        case (.boolean(let lValue), .boolean(let rValue)):
            return lValue == rValue
        case (.integer(let lValue), .integer(let rValue)):
            return lValue == rValue
        default:
            return false
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .boolean(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .integer(intValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "StandbyTime must be a string, boolean, or integer"
            )
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .boolean(let value):
            if value {
                try container.encode("true")
            } else {
                try container.encodeNil()
            }
        case .integer(let value):
            try container.encode(String(value))
        }
    }
    
    // APIで使用するための変換メソッド
    var value: String? {
        switch self {
        case .string(let value):
            return value
        case .boolean(let value):
            return value ? "true" : nil
        case .integer(let value):
            return String(value)
        }
    }
}
