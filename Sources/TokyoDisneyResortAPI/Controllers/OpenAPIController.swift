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
        do {
            // パラメータからparkTypeを取得
            // parkType は既に String型の列挙型として定義されている
            let parkTypeString = input.path.parkType.rawValue
            guard let parkType = ParkType(rawValue: parkTypeString) else {
                let errorResponse = Components.Schemas._Error(
                    status: 400,
                    reason: "Invalid park type. Use 'tdl' for Tokyo Disneyland or 'tds' for Tokyo DisneySea"
                )
                return .badRequest(.init(body: .json(errorResponse)))
            }
            
            // 空のリクエストを作成 (リポジトリがVapor.Requestを必要とするため)
            let request = Request(application: app, on: app.eventLoopGroup.next())
            
            // リポジトリからアトラクションデータを取得
            let attractions = try await attractionRepository.execute(
                parkType,
                request
            )
            
            // モデルの型を変換
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
            
            // 成功レスポンスを返す
            return .ok(.init(body: .json(openAPIAttractions)))
            
        } catch let error as Abort {
            // Abortエラーの種類に応じて適切なレスポンスを返す
            app.logger.error("Failed to get attraction data: \(error.reason)")
            
            let errorResponse = Components.Schemas._Error(
                status: Int32(error.status.code),
                reason: error.reason
            )
            
            switch error.status.code {
            case 400:
                return .badRequest(.init(body: .json(errorResponse)))
            case 404:
                return .notFound(.init(body: .json(errorResponse)))
            default:
                return .internalServerError(.init(body: .json(errorResponse)))
            }
            
        } catch {
            // その他のエラーは500エラーとしてラップ
            app.logger.error("Failed to get attraction data: \(error.localizedDescription)")
            
            let errorResponse = Components.Schemas._Error(
                status: 500,
                reason: "Failed to get attraction data: \(error.localizedDescription)"
            )
            return .internalServerError(.init(body: .json(errorResponse)))
        }
    }
}
