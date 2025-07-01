//
//  AttractionDataMapper.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

/// 未加工のアトラクションデータをドメインモデルに変換するマッパー
struct AttractionDataMapper: Sendable {
    /// 基本情報と運営状況を統合して完全なアトラクションモデルを作成
    /// - Parameters:
    ///   - basicInfoList: 基本情報リスト（アトラクション名、エリアなど）
    ///   - operatingStatusList: 運営状況リスト
    /// - Returns: 統合されたアトラクションモデル
    func integrateAttractionData(
        basicInfoList: [Attraction],
        operatingStatusList: [Attraction]
    ) -> [Attraction] {
        var attractions = [Attraction]()
        
        for basicInfo in basicInfoList {
            // 名前がマッチする運営状況を検索
            let matchingStatus = findMatchingStatus(for: basicInfo, in: operatingStatusList)
            
            // 運営状況があれば統合したAttraction構造体を作成
            if let status = matchingStatus {
                let attraction = Attraction(
                    area: basicInfo.area,
                    name: basicInfo.name,
                    iconTags: basicInfo.iconTags,
                    imageURL: basicInfo.imageURL,
                    detailURL: basicInfo.detailURL,
                    facilityID: status.facilityID,
                    facilityStatus: status.facilityStatus,
                    standbyTime: status.standbyTime,
                    operatingStatus: status.operatingStatus,
                    dpaStatus: status.dpaStatus,
                    fsStatus: status.fsStatus,
                    updateTime: status.updateTime,
                    operatingHoursFrom: status.operatingHoursFrom,
                    operatingHoursTo: status.operatingHoursTo
                )
                attractions.append(attraction)
            } else {
                // 運営状況がなければ基本情報のみのAttractionを追加
                attractions.append(basicInfo)
            }
        }
        
        return attractions
    }
    
    /// 基本情報に対応する運営状況を検索
    /// - Parameters:
    ///   - basicInfo: アトラクション基本情報
    ///   - operatingStatusList: 運営状況リスト
    /// - Returns: マッチする運営状況（見つからなければnil）
    private func findMatchingStatus(
        for basicInfo: Attraction,
        in operatingStatusList: [Attraction]
    ) -> Attraction? {
        // basicInfoのdetailURLにoperatingStatusListのfacilityIDが含まれているかをチェック
        // 含まれていたらマッチしたと判断
        return operatingStatusList.first {
            guard let facilityID = $0.facilityID else {
                return false
            }
            guard basicInfo.detailURL.contains(facilityID) else {
                return false
            }
            return true
        }
    }
}
