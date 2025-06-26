//
//  TokyoDisneyResortController.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Foundation
import Vapor
import Dependencies

struct TokyoDisneyResortController: RouteCollection {
    @Dependency(AttractionRepository.self) private var attractionRepository
    @Dependency(GreetingRepository.self) private var greetingRepository
    @Dependency(RestaurantRepository.self) private var restaurantRepository
    
    func boot(routes: any RoutesBuilder) throws {
        let myRoutes = routes.grouped("v1")
        // ParkType をパスパラメータとして受け取る
        myRoutes.get(":parkType", "attraction", use: getAttractionStatus)
        myRoutes.get(":parkType", "greeting", use: getGreetingStatus)
        myRoutes.get(":parkType", "restaurant", use: getRestaurantStatus)
    }
    
    /// ParkType に応じたアトラクション情報を返す
    func getAttractionStatus(request: Request) async throws -> Response {
        // URL から ParkType を取得
        guard let parkTypeString = request.parameters.get("parkType"),
              let parkType = ParkType(rawValue: parkTypeString) else {
            throw Abort(.badRequest, reason: "Invalid park type. Use 'tdl' for Tokyo Disneyland or 'tds' for Tokyo DisneySea")
        }
        
        do {
            let attractions = try await attractionRepository.execute(
                parkType,
                request
            )
            
            let response = Response(status: HTTPResponseStatus.ok)
            response.headers.contentType = .json
            try response.content.encode(attractions, as: .json)
            
            return response
        } catch let error as any AbortError {
            // AbortErrorに準拠したエラーは、そのステータスコードとメッセージを使用
            request.logger.error("Failed to get attraction data: \(error.reason)")
            throw error
        } catch {
            // その他のエラーは内部サーバーエラーとしてラップ
            request.logger.error("Failed to get attraction data: \(error.localizedDescription)")
            throw Abort(.internalServerError, reason: "Failed to get attraction data: \(error.localizedDescription)")
        }
    }
    
    /// ParkType に応じたグリーティング情報を返す
    func getGreetingStatus(request: Request) async throws -> Response {
        // URL から ParkType を取得
        guard let parkTypeString = request.parameters.get("parkType"),
              let parkType = ParkType(rawValue: parkTypeString) else {
            throw Abort(.badRequest, reason: "Invalid park type. Use 'tdl' for Tokyo Disneyland or 'tds' for Tokyo DisneySea")
        }
        
        do {
            let greetings = try await greetingRepository.execute(
                parkType,
                request
            )
            
            let response = Response(status: HTTPResponseStatus.ok)
            response.headers.contentType = .json
            try response.content.encode(greetings, as: .json)
            
            return response
        } catch let error as any AbortError {
            // AbortErrorに準拠したエラーは、そのステータスコードとメッセージを使用
            request.logger.error("Failed to get greeting data: \(error.reason)")
            throw error
        } catch {
            // その他のエラーは内部サーバーエラーとしてラップ
            request.logger.error("Failed to get greeting data: \(error.localizedDescription)")
            throw Abort(.internalServerError, reason: "Failed to get greeting data: \(error.localizedDescription)")
        }
    }
    
    /// ParkType に応じたレストラン情報を返す
    func getRestaurantStatus(request: Request) async throws -> Response {
        guard let parkTypeString = request.parameters.get("parkType"),
              let parkType = ParkType(rawValue: parkTypeString) else {
            throw Abort(.badRequest, reason: "Invalid park type. Use 'tdl' for Tokyo Disneyland or 'tds' for Tokyo DisneySea")
        }
        
        do {
            let restaurants = try await restaurantRepository.execute(
                parkType,
                request
            )
            
            let response = Response(status: HTTPResponseStatus.ok)
            response.headers.contentType = .json
            try response.content.encode(restaurants, as: .json)
            
            return response
        } catch let error as any AbortError {
            request.logger.error("Failed to get restaurant data: \(error.reason)")
            throw error
        } catch {
            request.logger.error("Failed to get restaurant data: \(error.localizedDescription)")
            throw Abort(.internalServerError, reason: "Failed to get restaurant data: \(error.localizedDescription)")
        }
    }
}
