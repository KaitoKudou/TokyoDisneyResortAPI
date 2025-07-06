//
//  GreetingDataMapper.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/17.
//

import Foundation

/// 未加工のグリーティングデータをドメインモデルに変換するマッパー
struct GreetingDataMapper: Sendable {
    /// 基本情報と運営状況を統合して完全なアトラクションモデルを作成
    /// - Parameters:
    ///   - basicInfoList: 基本情報リスト（アトラクション名、エリアなど）
    ///   - operatingStatusList: 運営状況リスト
    /// - Returns: 統合されたアトラクションモデル
    func integrateGreetingData(
        basicInfoList: [Greeting],
        operatingStatusList: [Greeting]
    ) -> [Greeting] {
        var greetings = [Greeting]()
        
        for basicInfo in basicInfoList {
            // 名前がマッチする運営状況を検索
            let matchingStatus = findMatchingStatus(for: basicInfo, in: operatingStatusList)
            
            // 運営状況があれば統合した Greeting 構造体を作成
            if let status = matchingStatus {
                let greeting = Greeting(
                    area: basicInfo.area,
                    name: basicInfo.name,
                    character: basicInfo.character,
                    imageURL: basicInfo.imageURL,
                    detailURL: basicInfo.detailURL,
                    facilityID: status.facilityID,
                    facilityName: status.facilityName,
                    facilityStatus: status.facilityStatus,
                    standbyTime: status.standbyTime,
                    operatingHours: status.operatingHours,
                    useStandbyTimeStyle: status.useStandbyTimeStyle,
                    updateTime: status.updateTime,
                )
                greetings.append(greeting)
            } else {
                // 運営状況がなければ基本情報のみのGreetingを追加
                greetings.append(basicInfo)
            }
        }
        
        return greetings
    }
    
    /// 基本情報に対応する運営状況を検索
    /// - Parameters:
    ///   - basicInfo: アトラクション基本情報
    ///   - operatingStatusList: 運営状況リスト
    /// - Returns: マッチする運営状況（見つからなければnil）
    private func findMatchingStatus(
        for basicInfo: Greeting,
        in operatingStatusList: [Greeting]
    ) -> Greeting? {
        // basicInfoのdetailURLにoperatingStatusListのfacilityIDが含まれているかをチェック
        // 含まれていたらマッチしたと判断
        return operatingStatusList.first {
            guard let facilityID = $0.facilityID else {
                return false
            }
            guard let detailURL = basicInfo.detailURL, detailURL.contains(facilityID) else {
                return false
            }
            return true
        }
    }
}
