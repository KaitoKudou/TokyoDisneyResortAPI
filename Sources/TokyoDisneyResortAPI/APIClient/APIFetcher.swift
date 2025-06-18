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
        } catch {
            throw error
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
            do {
                if T.self == Greeting.self {
                    // グリーティングの場合は入れ子構造を処理
                    do {
                        let greetingResponse = try decoder.decode(GreetingResponse.self, from: jsonData)
                        guard let facilities = greetingResponse.facilities as? [T] else {
                            request.logger.error("Failed to cast greeting facilities to expected type")
                            throw APIError.decodingFailed
                        }
                        request.logger.info("Successfully decoded \(facilities.count) facilities from nested structure")
                        return facilities
                    } catch {
                        // グリーティングデコードの詳細なエラーログ
                        request.logger.error("Failed to decode greeting response: \(error)")
                        
                        // JSONデータの一部をログに表示してデバッグを容易にする
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            // 長すぎる場合は一部だけを出力
                            let maxLength = 500
                            let trimmedString = jsonString.count > maxLength ? String(jsonString.prefix(maxLength)) + "..." : jsonString
                            request.logger.debug("JSON data sample: \(trimmedString)")
                        }
                        
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .keyNotFound(let key, let context):
                                request.logger.error("Key not found: \(key.stringValue), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                                request.logger.debug("Debug description: \(context.debugDescription)")
                                
                            case .valueNotFound(let type, let context):
                                request.logger.error("Value of type \(type) not found at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                                request.logger.debug("Debug description: \(context.debugDescription)")
                                
                            case .typeMismatch(let type, let context):
                                request.logger.error("Type mismatch: expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                                request.logger.debug("Debug description: \(context.debugDescription)")
                                
                            case .dataCorrupted(let context):
                                request.logger.error("Data corrupted: \(context.debugDescription)")
                                request.logger.debug("Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                                
                            @unknown default:
                                request.logger.error("Other decoding error: \(decodingError)")
                            }
                        }
                        throw error
                    }
                } else {
                    // その他の施設タイプは直接配列としてデコード
                    let facilities = try decoder.decode([T].self, from: jsonData)
                    request.logger.info("Successfully decoded \(facilities.count) facilities")
                    return facilities
                }
            } catch let decodingError {
                request.logger.error("Failed to decode facilities: \(decodingError)")
                throw APIError.decodingFailed
            }
        } catch {
            request.logger.error("Failed to fetch operating status: \(error.localizedDescription)")
            throw APIError.decodingFailed
        }
    }
}
