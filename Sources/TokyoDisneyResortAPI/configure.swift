import Vapor
import OpenAPIRuntime
import Foundation

// configures your application
public func configure(_ app: Application) async throws {
    // serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
