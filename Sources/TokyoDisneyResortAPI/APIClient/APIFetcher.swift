//
//  APIFetcher.swift
//  TokyoDisneyResortAPI
//
//  Created by GitHub Copilot on 2025/06/19.
//

import Foundation
import Vapor

/// APIデータの取得を担当する汎用型クラス
struct APIFetcher<T: Codable & Sendable>: Sendable {
    /// APIクライアント
    private let apiClient: TokyoDisneyResortClient
    
    /// 初期化
    /// - Parameter apiClient: 使用するAPIクライアント（デフォルトは新規インスタンス）
    init(apiClient: TokyoDisneyResortClient = .init()) {
        self.apiClient = apiClient
    }
    
    /// HTML形式の基本情報を取得
    /// - Parameters:
    ///   - parkType: パークタイプ
    ///   - facilityType: 施設タイプ
    ///   - parser: HTML解析用パーサー
    /// - Returns: パース済みの施設情報
    func fetchBasicInfo<Parser: FacilityHTMLParser>(
        parkType: ParkType,
        facilityType: FacilityType,
        parser: Parser
    ) async throws -> [T] where Parser.FacilityType == T {
        do {
            // APIクライアントからHTMLを取得
            let htmlString = try await apiClient.fetchHTMLString(
                parkType: parkType, 
                facilityType: facilityType
            )
            
            // HTML パーサーで施設情報を抽出
            let facilities = try parser.parseFacilities(from: htmlString)
            
            return facilities
        } catch let error as any AbortError {
            // AbortErrorに準拠したエラーはそのまま伝播
            throw error
        } catch {
            // その他のエラーは適切なAbortErrorにラップ
            throw Abort(.internalServerError, reason: "Failed to fetch basic facility information: \(error.localizedDescription)")
        }
    }
    
    /// JSON形式の運営状況を取得
    /// - Parameters:
    ///   - parkType: パークタイプ
    ///   - facilityType: 施設タイプ
    ///   - request: HTTPリクエスト
    /// - Returns: デコードされた施設情報
    func fetchOperatingStatus(
        parkType: ParkType, 
        facilityType: FacilityType, 
        request: Request
    ) async throws -> [T] {
        do {
            // API クライアントから運営状況データを取得
            let jsonData = try await apiClient.fetchOperatingStatus(
                parkType: parkType, 
                facilityType: facilityType
            )
            
            // デバッグ用にJSONデータをログに出力
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                request.logger.debug("Received JSON: \(String(jsonString.prefix(100)))...")
            }
            
            // JSONデコード
            let decoder = JSONDecoder()
            
            // 施設タイプに応じたデコード処理
            if T.self == Greeting.self {
                // グリーティングの場合は入れ子構造を処理
                let greetingResponse = try decoder.decode(GreetingResponse.self, from: jsonData)
                guard let facilities = greetingResponse.facilities as? [T] else {
                    request.logger.error("Failed to cast greeting facilities to expected type")
                    throw APIError.decodingFailed
                }
                request.logger.info("Successfully decoded \(facilities.count) facilities from nested structure")
                return facilities
            } else {
                // その他の施設タイプは直接配列としてデコード
                let facilities = try decoder.decode([T].self, from: jsonData)
                request.logger.info("Successfully decoded \(facilities.count) facilities")
                return facilities
            }
            
        } catch let error as any AbortError {
            // AbortErrorプロトコルに準拠したエラーはそのまま伝播
            request.logger.error("Error in fetchOperatingStatus: \(error.reason)")
            throw error
            
        } catch {
            // すべてのエラーをデコード失敗として処理するが、DecodingErrorの場合は詳細なログを出力
            if let decodingError = error as? DecodingError {
                request.logger.error("Decoding error in fetchOperatingStatus: \(decodingError)")
                
                // エラータイプに応じたログ出力
                switch decodingError {
                case .keyNotFound(let key, let context):
                    request.logger.error("Key not found: \(key.stringValue), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    request.logger.error("Value of type \(type) not found at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .typeMismatch(let type, let context):
                    request.logger.error("Type mismatch: expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    request.logger.error("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    request.logger.error("Other decoding error: \(decodingError)")
                }
            } else {
                request.logger.error("Failed to fetch operating status: \(error.localizedDescription)")
            }
            
            throw APIError.decodingFailed
        }
    }
}
