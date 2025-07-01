//
//  CustomCodingKey.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/26.
//

struct CustomCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
