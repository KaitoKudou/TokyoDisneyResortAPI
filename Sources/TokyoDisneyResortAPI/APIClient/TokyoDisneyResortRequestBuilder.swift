//
//  TokyoDisneyResortRequestBuilder.swift
//  TokyoDisneyResortAPI
//
//  Created by 工藤 海斗 on 2025/05/05.
//

import Foundation

struct TokyoDisneyResortRequestBuilder: TokyoDisneyResortRequest {
    var parkType: ParkType
    var facilityType: FacilityType
    
    init(parkType: ParkType, facilityType: FacilityType = .attraction) {
        self.parkType = parkType
        self.facilityType = facilityType
    }
    
    func buildURLRequest() -> URLRequest {
        let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        
        guard let url = components?.url else {
            fatalError("Invalid URL components: \(String(describing: components))")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        
        // ブラウザのような一般的なヘッダーを設定
        urlRequest.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        urlRequest.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        urlRequest.addValue("ja-JP,ja;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        
        return urlRequest
    }
}
