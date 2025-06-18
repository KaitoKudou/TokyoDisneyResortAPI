//
//  FacilityHTMLParser.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/18.
//

import SwiftSoup

/// HTML文書から施設情報を抽出する共通プロトコル
protocol FacilityHTMLParser: Sendable {
    associatedtype FacilityType
    
    /// HTML文字列から施設基本情報を抽出する
    /// - Parameter htmlString: 東京ディズニーリゾートのWebサイトから取得したHTML文字列
    /// - Returns: 抽出された施設情報
    /// - Throws: HTMLパースエラー
    func parseFacilities(from htmlString: String) throws -> [FacilityType]
    
    /// HTML文書から施設情報を抽出する
    /// - Parameter document: パース済みのHTMLドキュメント
    /// - Returns: 抽出された施設情報
    /// - Throws: HTMLパースエラー
    func extractFacilities(from document: Document) throws -> [FacilityType]
    
    /// HTMLから抽出した要素を施設モデルに変換する
    /// - Parameters:
    ///   - element: HTMLの要素
    /// - Returns: 作成された施設モデル
    /// - Throws: HTMLパースエラー
    func createFacilityModel(from element: Element) throws -> FacilityType
}

/// 共通の実装を提供するプロトコル拡張
extension FacilityHTMLParser {
    func parseFacilities(from htmlString: String) throws -> [FacilityType] {
        do {
            let document = try SwiftSoup.parse(htmlString)
            return try extractFacilities(from: document)
        } catch is Exception {
            throw HTMLParserError.parseError
        } catch {
            throw error
        }
    }
    
    func extractFacilities(from document: Document) throws -> [FacilityType] {
        var facilities = [FacilityType]()
        
        // data-categorize属性を持つli要素を探す
        let facilityLiItems = try document.select("li[data-categorize]")
        
        if facilityLiItems.isEmpty() {
            throw HTMLParserError.parseError
        }
        
        // 各施設の情報を解析
        for element in facilityLiItems {
            do {
                let facility = try createFacilityModel(from: element)
                facilities.append(facility)
            } catch {
                // 1つの施設解析に失敗してもその他は続行する
                continue
            }
        }
        
        if facilities.isEmpty {
            throw HTMLParserError.parseError
        }
        
        return facilities
    }
}
