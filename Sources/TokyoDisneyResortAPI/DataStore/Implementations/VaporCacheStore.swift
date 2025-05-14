//
//  VaporCacheStore.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Vapor

struct VaporCacheStore: CacheStoreProtocol {
    func get<T: Codable & Sendable>(_ key: String, as type: T.Type, request: Request) async throws -> T? {
        return try await request.cache.get(key, as: type)
    }
    
    func set<T: Codable & Sendable>(_ key: String, to value: T, expiresIn: CacheExpirationTime, request: Request) async throws {
        try await request.cache.set(key, to: value, expiresIn: expiresIn)
        request.logger.info("Cached \(key) for \(expiresIn)")
    }
}
