//
//  TokyoDisneyResortController.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/07/02.
//

import OpenAPIRuntime
import OpenAPIVapor
import Vapor
import Foundation
import Dependencies

/// パークタイプバリデーションエラー
struct ParkTypeValidationError: Error {
    let errorResponse: Components.Schemas.ErrorResponse
}

struct TokyoDisneyResortController: APIProtocol {
    @Dependency(AttractionRepository.self) private var attractionRepository
    @Dependency(GreetingRepository.self) private var greetingRepository
    @Dependency(RestaurantRepository.self) private var restaurantRepository
    private let app: Application
    
    init(app: Application) {
        self.app = app
    }
    
    // MARK: - Private Error Handling Methods
    
    /// パークタイプのバリデーション
    private func validateParkType(from rawValue: String) -> Result<ParkType, ParkTypeValidationError> {
        guard let parkType = ParkType(rawValue: rawValue) else {
            let errorResponse = Components.Schemas.ErrorResponse(
                statusCode: 400,
                message: "Invalid park type. Use 'tdl' for Tokyo Disneyland or 'tds' for Tokyo DisneySea"
            )
            return .failure(ParkTypeValidationError(errorResponse: errorResponse))
        }
        return .success(parkType)
    }
    
    /// エラーレスポンスの生成
    private func createErrorResponse(from error: any Error) -> (statusCode: Int32, response: Components.Schemas.ErrorResponse) {
        switch error {
        case let apiError as APIError:
            let statusCode = Int32(apiError.status.code)
            return (statusCode, Components.Schemas.ErrorResponse(
                statusCode: statusCode,
                message: apiError.description
            ))
            
        case let htmlError as HTMLParserError:
            let statusCode = Int32(htmlError.status.code)
            return (statusCode, Components.Schemas.ErrorResponse(
                statusCode: statusCode,
                message: htmlError.description
            ))
            
        default:
            return (500, Components.Schemas.ErrorResponse(
                statusCode: 500,
                message: "サーバー内部エラーが発生しました"
            ))
        }
    }
    
    /// アトラクション用のエラーレスポンス変換
    private func createAttractionErrorOutput(
        from error: any Error
    ) -> Operations.getAttractionStatus.Output {
        let (statusCode, errorResponse) = createErrorResponse(from: error)
        
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
    }
    
    /// グリーティング用のエラーレスポンス変換
    private func createGreetingErrorOutput(
        from error: any Error
    ) -> Operations.getGreetingStatus.Output {
        let (statusCode, errorResponse) = createErrorResponse(from: error)
        
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
    }
    
    /// レストラン用のエラーレスポンス変換
    private func createRestaurantErrorOutput(
        from error: any Error
    ) -> Operations.getRestaurantStatus.Output {
        let (statusCode, errorResponse) = createErrorResponse(from: error)
        
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
    }
    
    // MARK: - アトラクション取得
    func getAttractionStatus(_ input: Operations.getAttractionStatus.Input) async throws -> Operations.getAttractionStatus.Output {
        // パークタイプのバリデーション
        switch validateParkType(from: input.path.parkType.rawValue) {
        case .failure(let validationError):
            return .badRequest(.init(body: .json(validationError.errorResponse)))
        case .success(let parkType):
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
            } catch {
                return createAttractionErrorOutput(from: error)
            }
        }
    }
    
    // MARK: - グリーティング取得
    func getGreetingStatus(_ input: Operations.getGreetingStatus.Input) async throws -> Operations.getGreetingStatus.Output {
        // パークタイプのバリデーション
        switch validateParkType(from: input.path.parkType.rawValue) {
        case .failure(let validationError):
            return .badRequest(.init(body: .json(validationError.errorResponse)))
        case .success(let parkType):
            do {
                let greetings = try await greetingRepository.execute(parkType)
                
                let openAPIGreetings = greetings.map { greeting -> Components.Schemas.Greeting in
                    // operatingHoursの型変換
                    let convertedOperatingHours: Components.Schemas.Greeting.operatingHoursPayload? = greeting.operatingHours?.map {
                        Components.Schemas.Greeting.operatingHoursPayloadPayload(
                            operatingHoursFrom: $0.operatingHoursFrom,
                            operatingHoursTo: $0.operatingHoursTo,
                            operatingStatus: $0.operatingStatus
                        )
                    }
                    
                    return Components.Schemas.Greeting(
                        area: greeting.area,
                        name: greeting.name,
                        character: greeting.character,
                        imageURL: greeting.imageURL,
                        detailURL: greeting.detailURL,
                        facilityID: greeting.facilityID,
                        facilityName: greeting.facilityName,
                        facilityStatus: greeting.facilityStatus,
                        standbyTime: greeting.standbyTime?.value,
                        operatingHours: convertedOperatingHours,
                        useStandbyTimeStyle: greeting.useStandbyTimeStyle,
                        updateTime: greeting.updateTime
                    )
                }
                
                return .ok(.init(body: .json(openAPIGreetings)))
            } catch {
                return createGreetingErrorOutput(from: error)
            }
        }
    }
    
    // MARK: - レストラン取得
    func getRestaurantStatus(_ input: Operations.getRestaurantStatus.Input) async throws -> Operations.getRestaurantStatus.Output {
        // パークタイプのバリデーション
        switch validateParkType(from: input.path.parkType.rawValue) {
        case .failure(let validationError):
            return .badRequest(.init(body: .json(validationError.errorResponse)))
        case .success(let parkType):
            do {
                let restaurants = try await restaurantRepository.execute(parkType)
                
                let openAPIRestaurants = restaurants.map { restaurant -> Components.Schemas.Restaurant in
                    // operatingHoursの型変換
                    let convertedOperatingHours: Components.Schemas.Restaurant.operatingHoursPayload? = restaurant.operatingHours?.map {
                        Components.Schemas.Restaurant.operatingHoursPayloadPayload(
                            operatingHoursFrom: $0.operatingHoursFrom,
                            operatingHoursTo: $0.operatingHoursTo,
                            operatingStatus: $0.operatingStatus
                        )
                    }
                    
                    return Components.Schemas.Restaurant(
                        area: restaurant.area,
                        name: restaurant.name,
                        iconTags: restaurant.iconTags,
                        imageURL: restaurant.imageURL,
                        detailURL: restaurant.detailURL,
                        reservationURL: restaurant.reservationURL,
                        facilityID: restaurant.facilityID,
                        facilityName: restaurant.facilityName,
                        facilityStatus: restaurant.facilityStatus,
                        standbyTimeMin: restaurant.standbyTimeMin?.value,
                        standbyTimeMax: restaurant.standbyTimeMax?.value,
                        operatingHours: convertedOperatingHours,
                        useStandbyTimeStyle: restaurant.useStandbyTimeStyle,
                        updateTime: restaurant.updateTime,
                        popCornFlavor: restaurant.popCornFlavor
                    )
                }
                
                return .ok(.init(body: .json(openAPIRestaurants)))
            } catch {
                return createRestaurantErrorOutput(from: error)
            }
        }
    }
}
