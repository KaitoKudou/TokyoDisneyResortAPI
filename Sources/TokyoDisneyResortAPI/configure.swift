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
}

struct LowerCamelKey: CodingKey {
    var stringValue: String
    init(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}
