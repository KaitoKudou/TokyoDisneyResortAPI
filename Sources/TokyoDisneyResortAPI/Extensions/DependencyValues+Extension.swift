//
//  DependencyValues+Extension.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/07/08.
//

import Dependencies
import Vapor

extension DependencyValues {

  var request: Request {
    get { self[RequestKey.self] }
    set { self[RequestKey.self] = newValue }
  }

  private enum RequestKey: DependencyKey {
    static var liveValue: Request {
      fatalError("Value of type \(Value.self) is not registered in this context")
    }
  }
}
