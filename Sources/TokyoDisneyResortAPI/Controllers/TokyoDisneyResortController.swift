//
//  TokyoDisneyResortController.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Foundation
import SwiftSoup
import Vapor
import Dependencies

struct TokyoDisneyResortController: RouteCollection {
    @Dependency(\.attractionRepository) private var repository
    
    func boot(routes: any RoutesBuilder) throws {
        let myRoutes = routes.grouped("tokyo_disney_resort")
        // ParkType をパスパラメータとして受け取る
        myRoutes.get(":parkType", "attraction", use: getAttractionStatus)
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
            // リポジトリから統合されたアトラクション情報を取得
            let attractions = try await repository.getIntegratedAttractionInfo(
                parkType: parkType, 
                request: request
            )
            
            // JSONにエンコードしてレスポンスを作成
            let jsonData = try JSONEncoder().encode(attractions)
            let response = Response(status: HTTPResponseStatus.ok)
            response.headers.contentType = .json
            response.body = Response.Body(data: jsonData)
            
            return response
        } catch {
            request.logger.error("Failed to get attraction data: \(error)")
            return Response(
                status: HTTPResponseStatus.internalServerError,
                body: Response.Body(string: "Failed to get attraction data: \(error.localizedDescription)")
            )
        }
    }
}
