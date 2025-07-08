//
//  ErrorResponse.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/06/18.
//

import Foundation

/// See also: https://github.com/vapor/vapor/blob/aa6f3af9adcc9f5ba6fb9dcb3d69f24cef680b71/Sources/Vapor/Middleware/ErrorMiddleware.swift#L57
struct ErrorResponse: Codable {
    let statusCode: Int32
    let message: String
}
