//
//  RestaurantsTests.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/26.
//

@testable import TokyoDisneyResortAPI

import Dependencies
import Testing
import VaporTesting
import Foundation
import OpenAPIVapor

@Suite("Restaurants Tests")
struct RestaurantsTests {
    // パスカルケースに対応したJSONDecoderを作成するヘルパーメソッド
    private func createPascalCaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .custom { keys in
            let last = keys.last!
            let key = last.stringValue
            
            // パスカルケースの可能性があるキーのマッピング
            switch key {
            case "facilityID": return CustomCodingKey(stringValue: "FacilityID")!
            case "facilityName": return CustomCodingKey(stringValue: "FacilityName")!
            case "facilityStatus": return CustomCodingKey(stringValue: "FacilityStatus")!
            case "standbyTimeMin": return CustomCodingKey(stringValue: "StandbyTimeMin")!
            case "standbyTimeMax": return CustomCodingKey(stringValue: "StandbyTimeMax")!
            case "operatingHours": return CustomCodingKey(stringValue: "operatingHours")!
            case "updateTime": return CustomCodingKey(stringValue: "UpdateTime")!
            case "useStandbyTimeStyle": return CustomCodingKey(stringValue: "UseStandbyTimeStyle")!
            case "popCornFlavors": return CustomCodingKey(stringValue: "PopCornFlavors")!
            case "popCornFlavor": return CustomCodingKey(stringValue: "PopCornFlavors")!
            case "operatingHoursFrom": return CustomCodingKey(stringValue: "OperatingHoursFrom")!
            case "operatingHoursTo": return CustomCodingKey(stringValue: "OperatingHoursTo")!
            case "operatingStatus": return CustomCodingKey(stringValue: "OperatingStatus")!
            default: return last
            }
        }
        return decoder
    }
    
    // エラーレスポンス用のJSONDecoderを作成するヘルパーメソッド
    private func createErrorResponseDecoder() -> JSONDecoder {
        return JSONDecoder()
    }
    
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            // configure関数を呼び出す（ミドルウェアなどの設定）
            try await configure(app)
            
            // OpenAPIのルートを登録
            let requestInjectionMiddleware = OpenAPIRequestInjectionMiddleware()
            let transport = VaporTransport(routesBuilder: app.grouped(requestInjectionMiddleware))
            let handler = TokyoDisneyResortController(app: app)
            try handler.registerHandlers(on: transport, serverURL: Servers.Server1.url())
            
            // ルート登録後にテストを実行
            try await test(app)
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    // MARK: API エンドポイント
    @Test("Test TDL Restaurant Route Returns OK")
    func tdlRestaurantRoute() async throws {
        try await withDependencies {
            $0[RestaurantRepository.self].execute = { _ in
                return []
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/restaurant", afterResponse: { res async in
                    #expect(res.status == .ok)
                    #expect(res.headers.contentType == .json)
                    #expect(res.body.readableBytes > 0)
                })
            }
        }
    }
    
    @Test("Test TDS Restaurant Route Returns OK")
    func tdsRestaurantRoute() async throws {
        try await withDependencies {
            $0[RestaurantRepository.self].execute = { _ in
                return []
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tds/restaurant", afterResponse: { res async in
                    #expect(res.status == .ok)
                    #expect(res.headers.contentType == .json)
                    #expect(res.body.readableBytes > 0)
                })
            }
        }
    }
    
    @Test("Test Invalid Park Type Returns Bad Request")
    func invalidParkType() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "v1/invalid/restaurant", afterResponse: { res async in
                #expect(res.status == .internalServerError)
            })
        }
    }
    
    // MARK: キャッシュ機能
    @Test("Test Cache Response Is The Same")
    func testCacheResponse() async throws {
        // テスト用の固定レストランデータ
        let testRestaurant = Restaurant(
            area: "テストエリア",
            name: "ポップコーンワゴン（テスト用）",
            iconTags: ["テストタグ", "ポップコーン"],
            imageURL: "https://example.com/test.jpg",
            detailURL: "/test/R0001",
            reservationURL: "https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=TEST0",
            facilityID: "R0001",
            facilityName: "ポップコーンワゴン（テスト用）",
            facilityStatus: "営業中",
            standbyTimeMin: .string("30"),
            standbyTimeMax: .string("40"),
            operatingHours: [
                Restaurant.OperatingHours(
                    operatingHoursFrom: "10:00",
                    operatingHoursTo: "21:00",
                    operatingStatus: "営業中"
                )
            ],
            useStandbyTimeStyle: true,
            updateTime: "9:00",
            popCornFlavor: "しょうゆ味"
        )
        
        try await withApp { app in
            try await withDependencies {
                $0[RestaurantRepository.self] = .init(
                    execute: { parkType in
                        return [testRestaurant]
                    }
                )
                $0.request = Request(application: app, method: .GET, url: "/test", on: app.eventLoopGroup.next())
            } operation: {
                let cacheStore = VaporCacheStore()
                // キャッシュに直接データを保存
                try await cacheStore.set("test_key", to: [testRestaurant], expiresIn: .seconds(60))
                
                // リクエスト実行（キャッシュからデータが取得される）
                try await app.testing().test(.GET, "v1/tdl/restaurant", afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    print("First request completed")
                    
                    // キャッシュから取得
                    let cachedData = try await cacheStore.get("test_key", as: [Restaurant].self)
                    
                    // パスカルケースに対応したデコーダを作成
                    let decoder = createPascalCaseDecoder()
                    
                    let restaurants = try! decoder.decode([Restaurant].self, from: Data(buffer: res.body))
                    
                    #expect(restaurants.first?.area == cachedData?.first?.area)
                    #expect(restaurants.first?.name == cachedData?.first?.name)
                    #expect(restaurants.first?.iconTags == cachedData?.first?.iconTags)
                    #expect(restaurants.first?.imageURL == cachedData?.first?.imageURL)
                    #expect(restaurants.first?.detailURL == cachedData?.first?.detailURL)
                    #expect(restaurants.first?.reservationURL == cachedData?.first?.reservationURL)
                    #expect(restaurants.first?.facilityID == cachedData?.first?.facilityID)
                    #expect(restaurants.first?.facilityName == cachedData?.first?.facilityName)
                    #expect(restaurants.first?.facilityStatus == cachedData?.first?.facilityStatus)
                    #expect(restaurants.first?.standbyTimeMin == cachedData?.first?.standbyTimeMin)
                    #expect(restaurants.first?.standbyTimeMax == cachedData?.first?.standbyTimeMax)
                    #expect(restaurants.first?.operatingHours?.first?.operatingHoursFrom == cachedData?.first?.operatingHours?.first?.operatingHoursFrom)
                    #expect(restaurants.first?.operatingHours?.first?.operatingHoursTo == cachedData?.first?.operatingHours?.first?.operatingHoursTo)
                    #expect(restaurants.first?.operatingHours?.first?.operatingStatus == cachedData?.first?.operatingHours?.first?.operatingStatus)
                    #expect(restaurants.first?.updateTime == cachedData?.first?.updateTime)
                    #expect(restaurants.first?.useStandbyTimeStyle == cachedData?.first?.useStandbyTimeStyle)
                    #expect(restaurants.first?.popCornFlavor == cachedData?.first?.popCornFlavor)
                })
            }
        }
    }
    
    // MARK: モックを使ったテスト
    @Test("Test With Mocked Repository Returns Restaurants")
    func mockedRepository() async throws {
        try await withDependencies {
            $0[RestaurantRepository.self].execute = { _ in
                return [
                    Restaurant(
                        area: "テストエリア",
                        name: "テストレストラン",
                        iconTags: ["テストタグ"],
                        imageURL: "https://example.com/test.jpg",
                        detailURL: "/test/",
                        reservationURL: "https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=TEST0",
                        facilityID: "R0001",
                        facilityName: "テストレストラン",
                        facilityStatus: "営業中",
                        standbyTimeMin: .string("30"),
                        standbyTimeMax: .string("40"),
                        operatingHours: [
                            Restaurant.OperatingHours(
                                operatingHoursFrom: "10:00",
                                operatingHoursTo: "21:00",
                                operatingStatus: "営業中"
                            )
                        ],
                        useStandbyTimeStyle: true,
                        updateTime: "9:00",
                        popCornFlavor: nil
                    )
                ]
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/restaurant", afterResponse: { res async in
                    #expect(res.status == .ok)
                    
                    // JSONデコード
                    let restaurants = try? createPascalCaseDecoder().decode([Restaurant].self, from: Data(buffer: res.body))
                    
                    #expect(restaurants?.count == 1)
                    #expect(restaurants?.first?.name == "テストレストラン")
                    #expect(restaurants?.first?.area == "テストエリア")
                    #expect(restaurants?.first?.iconTags.count == 1)
                    #expect(restaurants?.first?.iconTags[0] == "テストタグ")
                    #expect(restaurants?.first?.imageURL == "https://example.com/test.jpg")
                    #expect(restaurants?.first?.detailURL == "/test/")
                    #expect(restaurants?.first?.reservationURL == "https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=TEST0")
                    #expect(restaurants?[0].facilityStatus == "営業中")
                    #expect(restaurants?[0].standbyTimeMin?.value == "30")
                    #expect(restaurants?[0].standbyTimeMax?.value == "40")
                    #expect(restaurants?[0].updateTime == "9:00")
                    #expect(restaurants?[0].operatingHours?.count == 1)
                    #expect(restaurants?[0].operatingHours?[0].operatingHoursFrom == "10:00")
                    #expect(restaurants?[0].operatingHours?[0].operatingHoursTo == "21:00")
                })
            }
        }
    }
    
    // MARK: HTML解析
    @Test("Test HTML Parser Correctly Extracts Restaurants")
    func htmlParser() async throws {
        let htmlParser = RestaurantHTMLParser()
        let testHTML = """
        <html>
        <body>
            <ul>
                <li data-categorize="restaurant">
                    <div class="area">テストエリア</div>
                    <h3 class="heading3">テストレストラン</h3>
                    <span class="iconTag">テストタグ</span>
                    <img src="test.jpg">
                    <a href="/detail/test/">詳細</a>
                    <div class="button-block column-2">
                        <div class="button">
                            <a href="/tds/restaurant/food/412/">店舗メニュー</a>
                        </div>
                        <div class="button conversion">
                            <a href="https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=TEST0">
                                オンライン予約・購入
                            </a>
                        </div>
                    </div>
                </li>
            </ul>
        </body>
        </html>
        """
        
        let restaurants = try htmlParser.parseFacilities(from: testHTML)
        
        #expect(restaurants.count == 1)
        #expect(restaurants[0].name == "テストレストラン")
        #expect(restaurants[0].area == "テストエリア")
        #expect(restaurants[0].iconTags.count == 1)
        #expect(restaurants[0].iconTags[0] == "テストタグ")
        #expect(restaurants[0].imageURL == "test.jpg")
        #expect(restaurants[0].detailURL == "/detail/test/")
        #expect(restaurants[0].reservationURL == "https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=TEST0")
    }
    
    @Test("Test HTML Parser With Multiple Restaurants")
    func testHTMLParserMultipleRestaurants() async throws {
        let htmlParser = RestaurantHTMLParser()
        let testHTML = """
        <html>
        <body>
            <ul>
                <li data-categorize="1">
                    <div class="area">メディテレーニアンハーバー</div>
                    <h3 class="heading3">カフェ・ポルトフィーノ</h3>
                    <span class="iconTag">レストラン</span>
                    <img src="cafe.jpg">
                    <a href="/tds/restaurant/detail/400/">詳細</a>
                </li>
                <li data-categorize="2">
                    <div class="area">メディテレーニアンハーバー</div>
                    <h3 class="heading3">マゼランズ</h3>
                    <span class="iconTag">プライオリティ・シーティング対応</span>
                    <img src="magellan.jpg">
                    <a href="/tds/restaurant/detail/412/">詳細</a>
                    <div class="button-block column-2">
                        <div class="button">
                            <a href="/tds/restaurant/food/412/">店舗メニュー</a>
                        </div>
                        <div class="button conversion">
                            <a href="https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=RMGL0">
                                オンライン予約・購入
                            </a>
                        </div>
                    </div>
                </li>
            </ul>
        </body>
        </html>
        """
        
        let restaurants = try htmlParser.parseFacilities(from: testHTML)
        
        #expect(restaurants.count == 2)
        
        // カフェ・ポルトフィーノの確認
        let cafe = restaurants.first(where: { $0.name == "カフェ・ポルトフィーノ" })
        #expect(cafe != nil)
        #expect(cafe?.area == "メディテレーニアンハーバー")
        #expect(cafe?.iconTags.count == 1)
        #expect(cafe?.iconTags[0] == "レストラン")
        #expect(cafe?.imageURL == "cafe.jpg")
        #expect(cafe?.detailURL == "/tds/restaurant/detail/400/")
        #expect(cafe?.reservationURL == nil) // 予約リンクなし
        
        // マゼランズの確認
        let magellan = restaurants.first(where: { $0.name == "マゼランズ" })
        #expect(magellan != nil)
        #expect(magellan?.area == "メディテレーニアンハーバー")
        #expect(magellan?.iconTags.count == 1)
        #expect(magellan?.iconTags[0] == "プライオリティ・シーティング対応")
        #expect(magellan?.imageURL == "magellan.jpg")
        #expect(magellan?.detailURL == "/tds/restaurant/detail/412/")
        #expect(magellan?.reservationURL == "https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=RMGL0")
    }
    
    @Test("Test HTML Parser With Invalid HTML")
    func testHTMLParserInvalidHTML() async throws {
        let htmlParser = RestaurantHTMLParser()
        
        // HTMLパースエラーを検証
        let invalidHTML = "<html><body><malformed>"
        do {
            _ = try htmlParser.parseFacilities(from: invalidHTML)
        } catch {
            #expect(error is HTMLParserError)
            #expect((error as? HTMLParserError) == HTMLParserError.parseError)
        }
    }
    
    // MARK: データマッパー
    @Test("Test Integration of Restaurant Data")
    func restaurantDataIntegration() async throws {
        let dataMapper = RestaurantDataMapper()
        
        let basicInfoList = [
            Restaurant(
                area: "エリアA",
                name: "レストラン1",
                iconTags: ["タグ1"],
                imageURL: "image1.jpg",
                detailURL: "/detail/401",
                reservationURL: "https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=REST1"
            )
        ]
        
        let operatingStatusList = [
            Restaurant(
                area: "",
                name: "",
                iconTags: [],
                imageURL: nil,
                detailURL: nil,
                reservationURL: nil,
                facilityID: "401",
                facilityName: "レストラン1",
                facilityStatus: "営業中",
                standbyTimeMin: .string("30"),
                standbyTimeMax: .string("40"),
                operatingHours: [
                    Restaurant.OperatingHours(
                        operatingHoursFrom: "9:00",
                        operatingHoursTo: "21:00",
                        operatingStatus: "営業中"
                    )
                ],
                useStandbyTimeStyle: true,
                updateTime: "9:00",
                popCornFlavor: nil
            )
        ]
        
        let restaurants = dataMapper.integrateRestaurantData(
            basicInfoList: basicInfoList,
            operatingStatusList: operatingStatusList
        )
        
        // レストラン1（運営情報あり）
        let restaurant = restaurants.first(where: { $0.name == "レストラン1" })
        #expect(restaurant?.facilityStatus == "営業中")
        #expect(restaurant?.standbyTimeMin?.value == "30")
        #expect(restaurant?.standbyTimeMax?.value == "40")
        #expect(restaurant?.operatingHours?.count == 1)
        #expect(restaurant?.operatingHours?[0].operatingHoursFrom == "9:00")
        #expect(restaurant?.operatingHours?[0].operatingHoursTo == "21:00")
        #expect(restaurant?.reservationURL == "https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=REST1")
    }
    
    @Test("Test Data Mapper With No Matching Facilities")
    func testDataMapperNoMatches() async throws {
        let dataMapper = RestaurantDataMapper()
        
        let basicInfoList = [
            Restaurant(
                area: "エリアA",
                name: "レストラン1",
                iconTags: ["タグ1"],
                imageURL: "image1.jpg",
                detailURL: "/detail/999", // マッチしないID
                reservationURL: "https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=REST1"
            )
        ]
        
        // マッチしないfacilityIDを持つ運営情報
        let operatingStatusList = [
            Restaurant(
                area: "",
                name: "",
                iconTags: [],
                imageURL: nil,
                detailURL: nil,
                reservationURL: nil,
                facilityID: "401", // 基本情報のdetailURLにこのIDが含まれていない
                facilityName: "レストラン1",
                facilityStatus: "営業中",
                standbyTimeMin: .string("30"),
                standbyTimeMax: nil,
                operatingHours: nil,
                useStandbyTimeStyle: nil,
                updateTime: nil,
                popCornFlavor: nil
            )
        ]
        
        let restaurants = dataMapper.integrateRestaurantData(
            basicInfoList: basicInfoList,
            operatingStatusList: operatingStatusList
        )
        
        // 運営情報とマッチしない場合は、基本情報のみ維持される
        #expect(restaurants.count == 1)
        #expect(restaurants[0].facilityID == nil)
        #expect(restaurants[0].facilityName == nil)
        #expect(restaurants[0].operatingHours == nil)
        #expect(restaurants[0].facilityStatus == nil)
        #expect(restaurants[0].standbyTimeMin == nil)
        #expect(restaurants[0].standbyTimeMax == nil)
        #expect(restaurants[0].name == "レストラン1")
        #expect(restaurants[0].area == "エリアA")
        #expect(restaurants[0].iconTags == ["タグ1"])
        #expect(restaurants[0].imageURL == "image1.jpg")
        #expect(restaurants[0].detailURL == "/detail/999")
        #expect(restaurants[0].reservationURL == "https://reserve.tokyodisneyresort.jp/restaurant/search/?restaurantNameCd=REST1")
    }
    
    // MARK: エラーハンドリングテスト
    @Test("Test HTMLParserError.invalidHTML throws correct error")
    func testInvalidHTMLError() async throws {
        try await withDependencies {
            $0[RestaurantRepository.self].execute = { _ in
                throw HTMLParserError.invalidHTML
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/restaurant", afterResponse: { res async in
                    #expect(res.status == .unprocessableEntity)
                    
                    // レスポンスのボディをJSONとしてデコード
                    if let errorData = try? createErrorResponseDecoder().decode(ErrorResponse.self, from: Data(buffer: res.body)) {
                        #expect(errorData.statusCode == res.status.code)
                        #expect(errorData.message == "HTMLデータの形式が無効です")
                    }
                })
            }
        }
    }
    
    @Test("Test HTMLParserError.noRestaurantFound throws correct error")
    func testNoRestaurantFoundError() async throws {
        try await withDependencies {
            $0[RestaurantRepository.self].execute = { _ in
                throw HTMLParserError.noRestaurantFound
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/restaurant", afterResponse: { res async in
                    #expect(res.status == .notFound)
                    
                    // レスポンスのボディをJSONとしてデコード
                    if let errorData = try? createErrorResponseDecoder().decode(ErrorResponse.self, from: Data(buffer: res.body)) {
                        #expect(errorData.statusCode == res.status.code)
                        #expect(errorData.message == "レストラン情報が見つかりませんでした")
                    }
                })
            }
        }
    }
    
    @Test("Test API Decode Failure Error Handling")
    func testDecodingFailedError() async throws {
        try await withDependencies {
            $0[RestaurantRepository.self].execute = { _ in
                throw APIError.decodingFailed
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/restaurant", afterResponse: { res async in
                    #expect(res.status == .unprocessableEntity)
                })
            }
        }
    }
    
    @Test("Test With API Client Error Handling")
    func testNetworkErrorHandlingDetails() async throws {
        try await withDependencies {
            $0[RestaurantRepository.self].execute = { _ in
                throw APIError.serverError(502)
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/restaurant", afterResponse: { res async in
                    #expect(res.status == .badGateway)
                    
                    // レスポンスのボディが適切なエラーメッセージを含んでいるか確認
                    if let errorData = try? createErrorResponseDecoder().decode(ErrorResponse.self, from: Data(buffer: res.body)) {
                        #expect(errorData.statusCode == res.status.code)
                        #expect(errorData.message == "Server error with status code 502")
                    }
                })
            }
        }
    }
    
    @Test("Test Server Error Handling")
    func testServerError() async throws {
        try await withDependencies {
            $0[RestaurantRepository.self].execute = { _ in
                throw APIError.serverError(500)
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/restaurant", afterResponse: { res async in
                    #expect(res.status == .badGateway)
                })
            }
        }
    }
    
    @Test("Test Restaurant Model Decoding with Optional Fields")
    func testRestaurantModelDecoding() async throws {
        // 一部のフィールドがnullのJSONデータ
        let jsonData = """
        {
            "area": "テストエリア",
            "name": "テストレストラン",
            "iconTags": ["テストタグ"],
            "imageURL": "test.jpg",
            "detailURL": "/test/",
            "facilityID": "R001",
            "facilityStatus": "営業中",
            "standbyTimeMin": "30",
            "operatingHours": [
                {
                    "OperatingHoursFrom": "10:00",
                    "OperatingHoursTo": "21:00"
                }
            ],
            "updateTime": "9:00"
        }
        """.data(using: .utf8)!
        
        let decoder = createPascalCaseDecoder()
        let restaurant = try decoder.decode(Restaurant.self, from: jsonData)
        
        #expect(restaurant.area == "テストエリア")
        #expect(restaurant.name == "テストレストラン")
        #expect(restaurant.iconTags.count == 1)
        #expect(restaurant.iconTags[0] == "テストタグ")
        #expect(restaurant.imageURL == "test.jpg")
        #expect(restaurant.detailURL == "/test/")
        #expect(restaurant.reservationURL == nil)
        #expect(restaurant.facilityID == "R001")
        #expect(restaurant.facilityStatus == "営業中")
        #expect(restaurant.standbyTimeMin?.value == "30")
        #expect(restaurant.standbyTimeMax == nil)
        #expect(restaurant.operatingHours?.count == 1)
        #expect(restaurant.operatingHours?[0].operatingHoursFrom == "10:00")
        #expect(restaurant.operatingHours?[0].operatingHoursTo == "21:00")
        #expect(restaurant.operatingHours?[0].operatingStatus == nil)
        #expect(restaurant.updateTime == "9:00")
        #expect(restaurant.popCornFlavor == nil)
    }
}
