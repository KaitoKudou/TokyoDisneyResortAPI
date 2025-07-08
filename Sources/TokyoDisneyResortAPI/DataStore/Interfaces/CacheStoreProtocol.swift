//
//  CacheStoreProtocol.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Vapor

protocol CacheStoreProtocol: Sendable {
    func get<T: Codable & Sendable>(_ key: String, as type: T.Type) async throws -> T?
    
    func set<T: Codable & Sendable>(_ key: String, to value: T, expiresIn: CacheExpirationTime) async throws
}
