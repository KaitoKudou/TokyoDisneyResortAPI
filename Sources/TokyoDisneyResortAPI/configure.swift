import Vapor
import OpenAPIRuntime
import Foundation

// configures your application
public func configure(_ app: Application) async throws {
    // serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
    
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .custom { codingPath in
        // lowerCamelCase に変換するためのカスタムロジック
        let original = codingPath.last!.stringValue
        let first    = original.prefix(1).lowercased()
        let rest     = original.dropFirst()
        return LowerCamelKey(stringValue: first + rest)
    }
    
    // `.json` メディアタイプで使用されるグローバルエンコーダーを上書き
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    
    // 統一されたエラーレスポンスを返すためのカスタムエラーハンドラーを設定
    app.middleware.use(ErrorMiddleware { req, error in
        let status: HTTPStatus
        let reason: String
        
        switch error {
        case let apiError as APIError:
            status = HTTPStatus(statusCode: Int(apiError.status.code))
            reason = apiError.description
            req.logger.error("API Error: \(apiError.description)")
            
        case let htmlError as HTMLParserError:
            status = HTTPStatus(statusCode: Int(htmlError.status.code))
            reason = htmlError.description
            req.logger.error("HTML Parser Error: \(htmlError.description)")
            
        case let abortError as any AbortError:
            status = HTTPStatus(statusCode: Int(abortError.status.code))
            reason = abortError.reason
            req.logger.error("Abort Error: \(abortError.reason)")
            
        default:
            // 未知のエラーはサーバーエラーとして処理
            status = .internalServerError
            reason = "サーバー内部エラーが発生しました"
            req.logger.error("Unknown Error: \(error.localizedDescription)")
        }
        
        // ErrorResponse形式に変換
        let errorResponse: [String: Any] = [
            "statusCode": status.code,
            "message": reason
        ]
        
        // JSONレスポンスを構築
        var headers = HTTPHeaders()
        headers.contentType = .json
        
        let response = Response(status: status, headers: headers)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: errorResponse)
            response.body = .init(data: jsonData)
        } catch {
            req.logger.error("Failed to encode error response: \(error)")
            // 最低限のJSONを手動で構築
            let fallbackJSON = "{\"statusCode\":\(status.code),\"message\":\"エラーレスポンスの生成に失敗しました\"}"
            response.body = .init(string: fallbackJSON)
        }
        
        return response
    })
}

struct LowerCamelKey: CodingKey {
    var stringValue: String
    init(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}
