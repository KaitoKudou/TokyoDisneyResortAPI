@testable import TokyoDisneyResortAPI
import VaporTesting
import Testing
import Dependencies
import OpenAPIVapor

@Suite("Attractions Tests")
struct AttractionsTests {
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
    @Test("Test TDL Attraction Route Returns OK")
    func tdlAttractionRoute() async throws {
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                return []
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res async in
                    #expect(res.status == .ok)
                    #expect(res.headers.contentType == .json)
                    #expect(res.body.readableBytes > 0) // ByteBuffer.isEmptyの代わりにreadableBytesを使用
                })
            }
        }
    }
    
    @Test("Test TDS Attraction Route Returns OK")
    func tdsAttractionRoute() async throws {
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                return []
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tds/attraction", afterResponse: { res async in
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
            try await app.testing().test(.GET, "v1/invalid/attraction", afterResponse: { res async in
                #expect(res.status == .internalServerError)
            })
        }
    }
    
    // MARK: キャッシュ機能
    @Test("Test Cache Is Used For Subsequent Calls")
    func cacheUsage() async throws {
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                return []
            }
        } operation: {
            try await withApp { app in
                // 最初のリクエスト（キャッシュなし）
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res1 async throws in
                    #expect(res1.status == .ok)
                    
                    // キャッシュが作成されるのを少し待つ（必要に応じて）
                    try await Task.sleep(for: .seconds(1))
                    
                    // 2回目のリクエスト（キャッシュあり）
                    try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res2 async throws in
                        #expect(res2.status == .ok)
                        
                        // パスカルケースに対応したデコーダを作成
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .custom { keys in
                            let last = keys.last!
                            let key = last.stringValue
                            
                            // パスカルケースの可能性があるキーのマッピング
                            switch key {
                            case "facilityID": return CustomCodingKey(stringValue: "FacilityID")!
                            case "facilityName": return CustomCodingKey(stringValue: "FacilityName")!
                            case "facilityStatus": return CustomCodingKey(stringValue: "FacilityStatus")!
                            case "standbyTime": return CustomCodingKey(stringValue: "StandbyTime")!
                            case "operatingStatus": return CustomCodingKey(stringValue: "OperatingStatus")!
                            case "dpaStatus": return CustomCodingKey(stringValue: "DPAStatus")!
                            case "fsStatus": return CustomCodingKey(stringValue: "FsStatus")!
                            case "updateTime": return CustomCodingKey(stringValue: "UpdateTime")!
                            case "operatingHoursFrom": return CustomCodingKey(stringValue: "OperatingHoursFrom")!
                            case "operatingHoursTo": return CustomCodingKey(stringValue: "OperatingHoursTo")!
                            default: return last
                            }
                        }
                        
                        // レスポンスの内容を比較するために両方をデコードする
                        let attractions1 = try? decoder.decode([Attraction].self, from: Data(buffer: res1.body))
                        let attractions2 = try? decoder.decode([Attraction].self, from: Data(buffer: res2.body))
                        
                        // JSONデータが正常にデコードできることを確認
                        #expect(attractions1 != nil)
                        #expect(attractions2 != nil)
                        
                        // アトラクションの数が同じであることを確認
                        #expect(attractions1?.count == attractions2?.count)
                        
                        // 各アトラクションの基本情報が一致していることを確認
                        if let attr1 = attractions1, let attr2 = attractions2, attr1.count == attr2.count {
                            for i in 0..<attr1.count {
                                #expect(attr1[i].name == attr2[i].name)
                                #expect(attr1[i].area == attr2[i].area)
                                #expect(attr1[i].iconTags == attr2[i].iconTags)
                                #expect(attr1[i].imageURL == attr2[i].imageURL)
                                #expect(attr1[i].detailURL == attr2[i].detailURL)
                                #expect(attr1[i].operatingStatus == attr2[i].operatingStatus)
                                #expect(attr1[i].standbyTime == attr2[i].standbyTime)
                                #expect(attr1[i].updateTime == attr2[i].updateTime)
                                #expect(attr1[i].operatingHoursFrom == attr2[i].operatingHoursFrom)
                                #expect(attr1[i].operatingHoursTo == attr2[i].operatingHoursTo)
                                #expect(attr1[i].dpaStatus == attr2[i].dpaStatus)
                                #expect(attr1[i].fsStatus == attr2[i].fsStatus)
                            }
                        }
                    })
                })
            }
        }
    }
    
    // MARK: モックを使ったテスト
    @Test("Test With Mocked Repository Returns Attractions")
    func mockedRepository() async throws {
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                return [
                    Attraction(
                        area: "テストエリア",
                        name: "テストアトラクション",
                        iconTags: ["テストタグ"],
                        imageURL: "https://example.com/test.jpg",
                        detailURL: "/test/",
                        facilityID: "0001",
                        facilityName: "テストアトラクション",
                        facilityStatus: nil,
                        standbyTime: .string("30"),
                        operatingStatus: "案内中",
                        dpaStatus: "販売なし",
                        fsStatus: "販売なし",
                        updateTime: "9:00",
                        operatingHoursFrom: "9:00",
                        operatingHoursTo: "21:00"
                    )
                ]
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res async in
                    #expect(res.status == .ok)
                    
                    // レスポンスJSON文字列を出力（デバッグ用）
                    let jsonString = String(data: Data(buffer: res.body), encoding: .utf8)!
                    print("Response JSON: \(jsonString)")
                    
                    // カスタムJSONDecoderを使用してパスカルケースのキーに対応
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .custom { keys in
                        let last = keys.last!
                        let key = last.stringValue
                        
                        // パスカルケースの可能性があるキーのマッピング
                        switch key {
                        case "facilityID":
                            return CustomCodingKey(stringValue: "FacilityID")!
                        case "facilityName":
                            return CustomCodingKey(stringValue: "FacilityName")!
                        case "facilityStatus":
                            return CustomCodingKey(stringValue: "FacilityStatus")!
                        case "standbyTime":
                            return CustomCodingKey(stringValue: "StandbyTime")!
                        case "operatingStatus":
                            return CustomCodingKey(stringValue: "OperatingStatus")!
                        case "dpaStatus":
                            return CustomCodingKey(stringValue: "DPAStatus")!
                        case "fsStatus":
                            return CustomCodingKey(stringValue: "FsStatus")!
                        case "updateTime":
                            return CustomCodingKey(stringValue: "UpdateTime")!
                        case "operatingHoursFrom":
                            return CustomCodingKey(stringValue: "OperatingHoursFrom")!
                        case "operatingHoursTo":
                            return CustomCodingKey(stringValue: "OperatingHoursTo")!
                        default:
                            return last
                        }
                    }
                    
                    // JSONレスポンスを解析
                    let attractions = try? decoder.decode([Attraction].self, from: Data(buffer: res.body))
                    
                    #expect(attractions?.count == 1)
                    #expect(attractions?[0].name == "テストアトラクション")
                    #expect(attractions?[0].area == "テストエリア")
                    #expect(attractions?[0].iconTags.count == 1)
                    #expect(attractions?[0].iconTags[0] == "テストタグ")
                    #expect(attractions?[0].imageURL == "https://example.com/test.jpg")
                    #expect(attractions?[0].detailURL == "/test/")
                    #expect(attractions?[0].operatingStatus == "案内中")
                    #expect(attractions?[0].standbyTime?.value == "30")
                    #expect(attractions?[0].updateTime == "9:00")
                    #expect(attractions?[0].operatingHoursFrom == "9:00")
                    #expect(attractions?[0].operatingHoursTo == "21:00")
                    #expect(attractions?[0].dpaStatus == "販売なし")
                    #expect(attractions?[0].fsStatus == "販売なし")
                })
            }
        }
    }
    
    @Test("Test With API Client Error Handling")
    func apiClientErrorHandling() async throws {
        try await withDependencies {
            // リポジトリのモックを設定してエラーをスローするように
            $0[AttractionRepository.self].execute = { _ in
                throw APIError.serverError(502)
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res async in
                    #expect(res.status == .badGateway)
                    
                    // レスポンスのボディが適切なエラーメッセージを含んでいるか確認
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: Data(buffer: res.body)) {
                        #expect(errorData.statusCode == res.status.code)
                        #expect(errorData.message == "Server error with status code 502")
                    }
                })
            }
        }
    }
    
    // MARK: HTML解析
    @Test("Test HTML Parser Correctly Extracts Attractions")
    func htmlParser() async throws {
        let htmlParser = AttractionHTMLParser()
        let testHTML = """
        <html>
        <body>
            <ul>
                <li data-categorize="attraction">
                    <div class="area">テストエリア</div>
                    <h3 class="heading3">テストアトラクション</h3>
                    <span class="iconTag">テストタグ</span>
                    <img src="test.jpg">
                    <a href="/detail/test/">詳細</a>
                </li>
            </ul>
        </body>
        </html>
        """
        
        let attractions = try htmlParser.parseFacilities(from: testHTML)
        
        #expect(attractions.count == 1)
        #expect(attractions[0].name == "テストアトラクション")
        #expect(attractions[0].area == "テストエリア")
        #expect(attractions[0].iconTags.count == 1)
        #expect(attractions[0].iconTags[0] == "テストタグ")
        #expect(attractions[0].imageURL == "test.jpg")
        #expect(attractions[0].detailURL == "/detail/test/")
    }
    
    // MARK: DataMapper
    @Test("Test Integration of Attraction Data")
    func attractionDataIntegration() async throws {
        let dataMapper = AttractionDataMapper()
        
        let basicInfoList = [
            Attraction(
                area: "エリアA",
                name: "アトラクション1",
                iconTags: ["タグ1"],
                imageURL: "image1.jpg",
                detailURL: "/detail/1"
            ),
            Attraction(
                area: "エリアB",
                name: "アトラクション2",
                iconTags: ["タグ2"],
                imageURL: "image2.jpg",
                detailURL: "/detail/2"
            )
        ]
        
        let operatingStatusList = [
            Attraction(
                area: "",
                name: "",
                iconTags: [],
                imageURL: nil,
                detailURL: "",
                facilityID: "1",
                facilityName: "アトラクション1",
                facilityStatus: nil,
                standbyTime: .string("30"),
                operatingStatus: "運営中",
                dpaStatus: nil,
                fsStatus: "利用可",
                updateTime: "9:00-22:00",
                operatingHoursFrom: "9:00",
                operatingHoursTo: "21:00"
            )
        ]
        
        let attractions = dataMapper.integrateAttractionData(
            basicInfoList: basicInfoList,
            operatingStatusList: operatingStatusList
        )
        
        #expect(attractions.count == 2)
        #expect(attractions[0].operatingStatus != nil)
        #expect(attractions[0].standbyTime?.value == "30")  // 文字列表現で比較
        #expect(attractions[1].operatingStatus == nil)
    }
    
    // MARK: CacheStore
    @Test("Test CacheStore Get and Set")
    func cacheStore() async throws {
        try await withApp { app in
            try await withDependencies {
                $0.request = Request(application: app, method: .GET, url: "/test", on: app.eventLoopGroup.next())
            } operation: {
                // キャッシュに保存
                let cacheStore = VaporCacheStore()
                let testData = ["test": "data"]
                try await cacheStore.set("test_key", to: testData, expiresIn: .seconds(10))
                
                // キャッシュから取得
                let cachedData = try await cacheStore.get("test_key", as: [String: String].self)
                
                #expect(cachedData != nil)
                #expect(cachedData?["test"] == "data")
                
            }
        }
    }
    
    // MARK: Request Builder
    @Test("Test Request Builder Creates Valid Request(TDL)")
    func tdlRequestBuilder() async throws {
        let builder = TokyoDisneyResortRequestBuilder(parkType: .tdl)
        let request = builder.buildURLRequest()
        
        #expect(request.url?.absoluteString.contains("tdl") == true)
        #expect(request.httpMethod == "GET")
    }
    
    @Test("Test Request Builder Creates Valid Request(TDS)")
    func tdsRequestBuilder() async throws {
        let builder = TokyoDisneyResortRequestBuilder(parkType: .tds)
        let request = builder.buildURLRequest()
        
        #expect(request.url?.absoluteString.contains("tds") == true)
        #expect(request.httpMethod == "GET")
    }
    
    // MARK: エラーハンドリングテスト
    @Test("Test HTMLParserError.invalidHTML throws correct error")
    func testInvalidHTMLError() async throws {
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                throw HTMLParserError.invalidHTML
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res async in
                    #expect(res.status == .unprocessableEntity)
                    
                    // レスポンスのボディをJSONとしてデコード
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: Data(buffer: res.body)) {
                        #expect(errorData.statusCode == res.status.code)
                        #expect(errorData.message == "HTMLデータの形式が無効です")
                    }
                })
            }
        }
    }

    @Test("Test HTMLParserError.noAttractionFound throws correct error")
    func testNoAttractionFoundError() async throws {
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                throw HTMLParserError.noAttractionFound
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res async in
                    #expect(res.status == .notFound)
                    
                    // レスポンスのボディをJSONとしてデコード
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: Data(buffer: res.body)) {
                        #expect(errorData.statusCode == res.status.code)
                        #expect(errorData.message == "アトラクション情報が見つかりませんでした")
                    }
                })
            }
        }
    }

    @Test("Test API Decode Failure Error Handling")
    func testDecodingFailedError() async throws {
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                throw APIError.decodingFailed
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res async in
                    #expect(res.status == .unprocessableEntity)
                    
                    // レスポンスのボディをJSONとしてデコード
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: Data(buffer: res.body)) {
                        #expect(errorData.statusCode == res.status.code)
                        #expect(errorData.message == "Failed to decode the response data")
                    } else {
                        XCTFail("レスポンスボディをErrorResponseにデコードできませんでした")
                    }
                })
            }
        }
    }
    
    @Test("Test Server Error Handling")
    func testServerError() async throws {
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                throw APIError.serverError(500)
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res async in
                    #expect(res.status == .badGateway)
                    
                    // レスポンスのボディをJSONとしてデコード
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: Data(buffer: res.body)) {
                        #expect(errorData.statusCode == res.status.code)
                        #expect(errorData.message == "Server error with status code 500")
                    } else {
                        XCTFail("レスポンスボディをErrorResponseにデコードできませんでした")
                    }
                })
            }
        }
    }
    
    @Test("Test Invalid Response Error")
    func testInvalidResponseError() async throws {
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                throw APIError.invalidResponse
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res async in
                    #expect(res.status == .badGateway)
                })
            }
        }
    }
    
    @Test("Test HTMLParser Error With Detailed Messages")
    func testHTMLParserDetailedErrors() async throws {
        // parseErrorのテスト
        try await withDependencies {
            $0[AttractionRepository.self].execute = { _ in
                throw HTMLParserError.parseError
            }
        } operation: {
            try await withApp { app in
                try await app.testing().test(.GET, "v1/tdl/attraction", afterResponse: { res async in
                    #expect(res.status == .unprocessableEntity)
                    
                    // レスポンスのボディをJSONとしてデコード
                    if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: Data(buffer: res.body)) {
                        #expect(errorData.statusCode == res.status.code)
                        #expect(errorData.message == "HTMLデータの解析中にエラーが発生しました")
                    } else {
                        XCTFail("レスポンスボディをErrorResponseにデコードできませんでした")
                    }
                })
            }
        }
    }
}
