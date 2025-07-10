//
//  RestaurantDataMapper.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/25.
//

import Foundation

/// 未加工のレストランデータをドメインモデルに変換するマッパー
struct RestaurantDataMapper {
    /// 基本情報と運営状況を統合して完全なレストランモデルを作成
    /// - Parameters:
    ///   - basicInfoList: 基本情報リスト（レストラン名、エリアなど）
    ///   - operatingStatusList: 運営状況リスト
    /// - Returns: 統合された Restaurant モデル
    func integrateRestaurantData(
        basicInfoList: [Restaurant],
        operatingStatusList: [Restaurant]
    ) -> [Restaurant] {
        var restaurants = [Restaurant]()
        
        for basicInfo in basicInfoList {
            // 名前がマッチする運営状況を検索
            let matchingStatus = findMatchingStatus(for: basicInfo, in: operatingStatusList)
            
            // 運営状況があれば統合した Restaurant 構造体を作成
            if let status = matchingStatus {
                let restaurant = Restaurant(
                    area: basicInfo.area,
                    name: basicInfo.name,
                    iconTags: basicInfo.iconTags,
                    imageURL: basicInfo.imageURL,
                    detailURL: basicInfo.detailURL,
                    reservationURL: basicInfo.reservationURL,
                    facilityID: status.facilityID,
                    facilityStatus: status.facilityStatus,
                    standbyTimeMin: status.standbyTimeMin,
                    standbyTimeMax: status.standbyTimeMax,
                    operatingHours: status.operatingHours,
                    useStandbyTimeStyle: status.useStandbyTimeStyle,
                    updateTime: status.updateTime,
                    popCornFlavor: status.popCornFlavor
                )
                restaurants.append(restaurant)
            } else {
                // 運営状況がなければ基本情報のみの Restaurant を追加
                restaurants.append(basicInfo)
            }
        }
        
        return restaurants
    }
    
    /// 基本情報に対応する運営状況を検索
    /// - Parameters:
    ///   - basicInfo: レストラン基本情報
    ///   - operatingStatusList: 運営状況リスト
    /// - Returns: マッチする運営状況（見つからなければnil）
    private func findMatchingStatus(
        for basicInfo: Restaurant,
        in operatingStatusList: [Restaurant]
    ) -> Restaurant? {
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
