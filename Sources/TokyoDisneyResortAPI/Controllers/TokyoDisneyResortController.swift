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
    
    func boot(routes: any RoutesBuilder) throws {
        let myRoutes = routes.grouped("tokyo_disney_resort")
        // ParkType をパスパラメータとして受け取る
        myRoutes.get(":parkType", "attraction", use: getAttractionStatus)
        myRoutes.get(":parkType", "greeting", use: getGreetingStatus)
    }
    
    /// ParkType に応じたアトラクション情報を返す
    func getAttractionStatus(request: Request) async throws -> Response {
        // URL から ParkType を取得
        guard let parkTypeString = request.parameters.get("parkType"),
              let parkType = ParkType(rawValue: parkTypeString) else {
            return Response(status: HTTPResponseStatus.badRequest,
                           body: Response.Body(string: "Invalid park type. Use 'tdl' for Tokyo Disneyland or 'tds' for Tokyo DisneySea"))
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
        } catch {
            request.logger.error("Failed to get attraction data: \(error)")
            return Response(
                status: HTTPResponseStatus.internalServerError,
                body: Response.Body(string: "Failed to get attraction data: \(error.localizedDescription)")
            )
        }
    }
    
    /// ParkType に応じたグリーティング情報を返す
    func getGreetingStatus(request: Request) async throws -> Response {
        // URL から ParkType を取得
        guard let parkTypeString = request.parameters.get("parkType"),
              let parkType = ParkType(rawValue: parkTypeString) else {
            return Response(status: HTTPResponseStatus.badRequest,
                           body: Response.Body(string: "Invalid park type. Use 'tdl' for Tokyo Disneyland or 'tds' for Tokyo DisneySea"))
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
        } catch {
            request.logger.error("Failed to get greeting data: \(error)")
            return Response(
                status: HTTPResponseStatus.internalServerError,
                body: Response.Body(string: "Failed to get greeting data: \(error.localizedDescription)")
            )
        }
    }
}
