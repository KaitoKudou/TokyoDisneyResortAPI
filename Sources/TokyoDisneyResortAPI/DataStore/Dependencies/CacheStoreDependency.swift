//
//  CacheStoreDependency.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Dependencies

private enum CacheStoreKey: DependencyKey {
    static let liveValue: any CacheStoreProtocol = VaporCacheStore()
}

extension DependencyValues {
    var cacheStore: any CacheStoreProtocol {
        get { self[CacheStoreKey.self] }
        set { self[CacheStoreKey.self] = newValue }
    }
}
