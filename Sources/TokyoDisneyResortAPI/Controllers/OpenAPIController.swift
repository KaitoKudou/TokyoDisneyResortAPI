//
//  OpenAPIController.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/07/02.
//

import OpenAPIRuntime
import OpenAPIVapor
import Vapor
import Foundation
import Dependencies

struct OpenAPIController: APIProtocol {
    @Dependency(AttractionRepository.self) private var attractionRepository
    private let app: Application
    
    init(app: Application) {
        self.app = app
    }
    
    func getAttractionStatus(_ input: Operations.getAttractionStatus.Input) async throws -> Operations.getAttractionStatus.Output {
        let parkTypeString = input.path.parkType.rawValue
        guard let parkType = ParkType(rawValue: parkTypeString) else {
            // 不正なパークタイプの場合はBadRequestを返す
            let errorResponse = Components.Schemas.ErrorResponse(
                statusCode: 400,
                message: "Invalid park type. Use 'tdl' for Tokyo Disneyland or 'tds' for Tokyo DisneySea"
            )
            return .badRequest(.init(body: .json(errorResponse)))
        }
        
        do {
            let attractions = try await attractionRepository.execute(parkType)
            
            let openAPIAttractions = attractions.map { attraction -> Components.Schemas.Attraction in
                return Components.Schemas.Attraction(
                    area: attraction.area,
                    name: attraction.name,
                    iconTags: attraction.iconTags,
                    imageURL: attraction.imageURL,
                    detailURL: attraction.detailURL,
                    facilityID: attraction.facilityID,
                    facilityStatus: attraction.facilityStatus,
                    standbyTime: attraction.standbyTime?.value,
                    operatingStatus: attraction.operatingStatus,
                    dpaStatus: attraction.dpaStatus,
                    fsStatus: attraction.fsStatus,
                    updateTime: attraction.updateTime,
                    operatingHoursFrom: attraction.operatingHoursFrom,
                    operatingHoursTo: attraction.operatingHoursTo
                )
            }
            
            return .ok(.init(body: .json(openAPIAttractions)))
        } catch let error as APIError {
            let statusCode = Int32(error.status.code)
            let errorResponse = Components.Schemas.ErrorResponse(
                statusCode: statusCode,
                message: error.description
            )
            
            switch statusCode {
            case 400:
                return .badRequest(.init(body: .json(errorResponse)))
            case 404:
                return .notFound(.init(body: .json(errorResponse)))
            case 422:
                return .unprocessableContent(.init(body: .json(errorResponse)))
            case 502:
                return .badGateway(.init(body: .json(errorResponse)))
            default:
                return .internalServerError(.init(body: .json(errorResponse)))
            }
            
        } catch let error as HTMLParserError {
            let statusCode = Int32(error.status.code)
            let errorResponse = Components.Schemas.ErrorResponse(
                statusCode: statusCode,
                message: error.description
            )
            
            if statusCode == 422 {
                return .unprocessableContent(.init(body: .json(errorResponse)))
            } else if statusCode == 400 {
                return .badRequest(.init(body: .json(errorResponse)))
            } else if statusCode == 404 {
                return .notFound(.init(body: .json(errorResponse)))
            } else {
                return .internalServerError(.init(body: .json(errorResponse)))
            }
            
        } catch {
            let errorResponse = Components.Schemas.ErrorResponse(
                statusCode: 500,
                message: "サーバー内部エラーが発生しました"
            )
            return .internalServerError(.init(body: .json(errorResponse)))
        }
    }
}
