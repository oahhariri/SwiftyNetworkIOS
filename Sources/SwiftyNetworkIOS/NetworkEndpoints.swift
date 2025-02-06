//
//  NetworkEndpoints.swift
//  SwiftyNetworkIOS
//
//  Created by Abdulrahman Hariri on 18/02/1444 AH.
//

import Alamofire

public protocol NetworkEndpoints {
    var info: EndpointInfo { get }
}

public struct EndpointInfo {
    public let path: String
    public let method: HTTPMethod
    public let customBaseUrl: String?

    public init(_ path: String, _ method: HTTPMethod, customBaseUrl: String? = nil) {
        self.path = path
        self.method = method
        self.customBaseUrl = customBaseUrl
    }
}
