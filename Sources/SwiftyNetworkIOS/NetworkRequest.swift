//
//  NetworkRequest.swift
//  SwiftyNetworkIOS
//
//  Created by Abdulrahman Hariri on 18/02/1444 AH.
//

import Alamofire
import SwiftyJSON

public struct NetworkRequest {
    let networkEndpoints:NetworkEndpoints?
    let endpoint: EndpointInfo
    let header: HTTPHeaders
    let parameters: Parameters

    public init(_ networkEndpoints:NetworkEndpoints, header: HTTPHeaders = [:], parameters: Parameters = [:]) {
        self.endpoint = networkEndpoints.info
        self.header = header
        self.parameters = parameters
        self.networkEndpoints = networkEndpoints
    }
    
    public init(_ networkEndpoints:NetworkEndpoints?=nil,endpoint: EndpointInfo, header: HTTPHeaders = [:], parameters: Parameters = [:]) {
        self.endpoint = endpoint
        self.header = header
        self.parameters = parameters
        self.networkEndpoints = networkEndpoints
    }
    
    public func getEndpoint() -> EndpointInfo {
        return endpoint
    }
    
    public func getHeaders() -> HTTPHeaders {
        return header
    }
    
    public func getParameters() -> Parameters {
        return parameters
    }
    
    public func getNetworkEndpoints() -> NetworkEndpoints? {
        return networkEndpoints
    }
}

public struct NetworkUploadRequest {
    let networkEndpoints:NetworkEndpoints?
    let endpoint: EndpointInfo
    let header: HTTPHeaders
    let data: MultipartFormData

    public init(_ networkEndpoints:NetworkEndpoints?=nil, endpoint: EndpointInfo, header: HTTPHeaders = [:], data: MultipartFormData) {
        self.endpoint = endpoint
        self.header = header
        self.data = data
        self.networkEndpoints = networkEndpoints
    }
    
    public init(_ networkEndpoints:NetworkEndpoints, header: HTTPHeaders = [:], data: MultipartFormData) {
        self.endpoint = networkEndpoints.info
        self.header = header
        self.data = data
        self.networkEndpoints = networkEndpoints
    }
    
    public func getEndpoint() -> EndpointInfo {
        return endpoint
    }
    
    public func getHeaders() -> HTTPHeaders {
        return header
    }
    
    public func getData() -> MultipartFormData {
        return data
    }
    
    public func getNetworkEndpoints() -> NetworkEndpoints? {
        return networkEndpoints
    }
}
