//
//  AttractionRepositoryDependency.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Dependencies

private enum AttractionRepositoryKey: DependencyKey {
    static let liveValue: any AttractionRepositoryProtocol = AttractionRepository()
}

extension DependencyValues {
    var attractionRepository: any AttractionRepositoryProtocol {
        get { self[AttractionRepositoryKey.self] }
        set { self[AttractionRepositoryKey.self] = newValue }
    }
}
