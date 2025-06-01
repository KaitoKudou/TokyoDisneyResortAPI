//
//  MockAttractionRepository.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Foundation
import Vapor

/// テスト用のモックリポジトリ
struct MockAttractionRepository: AttractionRepositoryProtocol {
    /// アトラクション基本情報を取得するカスタムロジック
    var fetchAttractionBasicInfoHandler: @Sendable (ParkType) async throws -> [Attraction] = { _ in
        return [] // デフォルトは空配列
    }
    
    /// アトラクション運営状況を取得するカスタムロジック
    var fetchOperatingStatusHandler: @Sendable (ParkType, Request) async throws -> [Attraction] = { _, _ in
        return [] // デフォルトは空配列
    }
    
    /// キャッシュから統合情報を取得するカスタムロジック
    var getCachedIntegratedInfoHandler: @Sendable (ParkType, Request) async throws -> [Attraction]? = { _, _ in
        return nil // デフォルトはnil（キャッシュなし）
    }
    
    /// キャッシュに統合情報を保存するカスタムロジック
    var cacheIntegratedInfoHandler: @Sendable ([Attraction], ParkType, Request) async throws -> Void = { _, _, _ in }
    
    /// 統合されたアトラクション情報を取得するカスタムロジック
    var getIntegratedAttractionInfoHandler: @Sendable (ParkType, Request) async throws -> [Attraction] = { _, _ in
        return [] // デフォルトは空配列
    }
    
    // プロトコル実装メソッド - 各メソッドは対応するハンドラに処理を委譲
    
    func fetchAttractionBasicInfo(parkType: ParkType) async throws -> [Attraction] {
        try await fetchAttractionBasicInfoHandler(parkType)
    }
    
    func fetchOperatingStatus(parkType: ParkType, request: Request) async throws -> [Attraction] {
        try await fetchOperatingStatusHandler(parkType, request)
    }
    
    func getCachedIntegratedInfo(parkType: ParkType, request: Request) async throws -> [Attraction]? {
        try await getCachedIntegratedInfoHandler(parkType, request)
    }
    
    func cacheIntegratedInfo(attractions: [Attraction], parkType: ParkType, request: Request) async throws {
        try await cacheIntegratedInfoHandler(attractions, parkType, request)
    }
    
    /// プロトコル要件の実装 - AttractionRepositoryProtocolで定義されたメソッド
    func getIntegratedAttractionInfo(parkType: ParkType, request: Request) async throws -> [Attraction] {
        try await getIntegratedAttractionInfoHandler(parkType, request)
    }
}