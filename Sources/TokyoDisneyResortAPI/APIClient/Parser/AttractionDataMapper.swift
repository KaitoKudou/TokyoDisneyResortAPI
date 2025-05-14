//
//  AttractionDataMapper.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

/// 未加工のアトラクションデータをドメインモデルに変換するマッパー
struct AttractionDataMapper: Sendable {
    /// 運営状況とアトラクション基本情報から完全なアトラクションモデルを作成
    /// - Parameters:
    ///   - basicInfoList: アトラクション基本情報リスト
    ///   - operatingStatusList: 運営状況リスト
    /// - Returns: 統合されたアトラクションモデル
    func integrateAttractionData(
        basicInfoList: [AttractionBasicInfo],
        operatingStatusList: [AttractionOperatingStatus]
    ) -> [Attraction] {
        var attractions = [Attraction]()
        
        for basicInfo in basicInfoList {
            // 名前がマッチする運営状況を検索
            let matchingStatus = findMatchingStatus(for: basicInfo, in: operatingStatusList)
            
            // 統合したAttraction構造体を作成
            let attraction = Attraction(basicInfo: basicInfo, operatingStatus: matchingStatus)
            attractions.append(attraction)
        }
        
        return attractions
    }
    
    /// 基本情報に対応する運営状況を検索
    /// - Parameters:
    ///   - basicInfo: アトラクション基本情報
    ///   - operatingStatusList: 運営状況リスト
    /// - Returns: マッチする運営状況（見つからなければnil）
    private func findMatchingStatus(
        for basicInfo: AttractionBasicInfo,
        in operatingStatusList: [AttractionOperatingStatus]
    ) -> AttractionOperatingStatus? {
        // 名前がマッチする運営状況を検索
        return operatingStatusList.first { 
            // facilityNameとアトラクション名を正規化して比較
            let normalizedFacilityName = $0.facilityName
                .replacingOccurrences(of: " ", with: "")
                .lowercased()
            let normalizedAttractionName = basicInfo.name
                .replacingOccurrences(of: " ", with: "")
                .lowercased()
            
            return normalizedFacilityName.contains(normalizedAttractionName) ||
                   normalizedAttractionName.contains(normalizedFacilityName)
        }
    }
    
    /// データ取得に失敗した場合のフォールバックアトラクションデータを生成
    /// - Returns: ダミーのアトラクション基本情報リスト
    func createFallbackAttractions() -> [AttractionBasicInfo] {
        return [
            AttractionBasicInfo(
                area: "メディテレーニアンハーバー",
                name: "ソアリン：ファンタスティック・フライト",
                iconTags: ["ファストパス対象", "身長制限あり"],
                imageURL: "https://www.example.com/soaring.jpg",
                detailURL: "/attractions/soaring/"
            ),
            AttractionBasicInfo(
                area: "アラビアンコースト",
                name: "マジックランプシアター",
                iconTags: ["雨の日でも安心"],
                imageURL: "https://www.example.com/magiclamp.jpg",
                detailURL: "/attractions/magiclamp/"
            ),
            AttractionBasicInfo(
                area: "マーメイドラグーン",
                name: "アリエルのプレイグラウンド",
                iconTags: ["子供向け"],
                imageURL: "https://www.example.com/ariel.jpg",
                detailURL: "/attractions/ariel/"
            )
        ]
    }
}
