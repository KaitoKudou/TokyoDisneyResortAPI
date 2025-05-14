//
//  AttractionOperatingStatus.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

/// アトラクションの案内状況を表す構造体
struct AttractionOperatingStatus: Codable {
    let facilityID: String
    let facilityName: String
    let standbyTime: StandbyTime?
    let operatingStatus: String?
    let dpaStatus: String?
    let fsStatus: String?
    let updateTime: String?
    let operatingHoursFrom: String?
    let operatingHoursTo: String?
    
    private enum CodingKeys: String, CodingKey {
        case facilityID = "FacilityID"
        case facilityName = "FacilityName"
        case standbyTime = "StandbyTime"
        case operatingStatus = "OperatingStatus"
        case dpaStatus = "DPAStatus"
        case fsStatus = "FsStatus"
        case updateTime = "UpdateTime"
        case operatingHoursFrom = "OperatingHoursFrom"
        case operatingHoursTo = "OperatingHoursTo"
    }
}

// String型とBool型の両方を受け付けるためのカスタムタイプ
enum StandbyTime: Codable, Equatable {
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
    
    case string(String)
    case boolean(Bool)
    case integer(Int)
    
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
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        }
    }
    
    // 文字列表現を返すためのヘルパーメソッド
    var description: String {
        switch self {
        case .string(let value):
            return value
        case .boolean(let value):
            return value ? "true" : "false"
        case .integer(let value):
            return String(value)
        }
    }
}
