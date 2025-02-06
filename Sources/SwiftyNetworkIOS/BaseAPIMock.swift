//
//  BaseAPIMock.swift
//  SwiftyNetworkIOS
//
//  Created by Omar Ameen Hariri  on 21/08/2024.
//

import Alamofire
import Foundation

public class BaseAPIMock<RequestAdapter: APIRequestAdapter>: BaseAPI<RequestAdapter> {
    private var mockResponse: Any?
    public var requst: NetworkRequest?
    public var uploadRequst: NetworkUploadRequest?
    
    public func setMockResponse<T: NetworkModel>(_ response: BaseAPI<RequestAdapter>.Result<T>) {
        mockResponse = response
    }
    
    override public func request<T: NetworkModel>(_ requst: NetworkRequest, parameterEncoding: ParameterEncoding? = nil, automaticallyCancelling shouldAutomaticallyCancel: Bool = false, isEmptyResponse: Bool = false, model: T.Type, _ onDecodeFaluier: ((Data?) -> (DecodeResult<T>))? = nil) async -> BaseAPI<RequestAdapter>.Result<T> {
        guard let mockResponse = mockResponse as? BaseAPI<RequestAdapter>.Result<T> else { return .onFailure(nil) }
        self.requst = requst
        return mockResponse
    }
    
    override public func uploadMultipart<T: NetworkModel>(_ requst: NetworkUploadRequest, automaticallyCancelling shouldAutomaticallyCancel: Bool = false, isEmptyResponse: Bool = false, model: T.Type, _ uploadProgress: (@MainActor (Double) -> ())? = nil, _ onDecodeFaluier: ((Data?) -> (DecodeResult<T>))? = nil) async -> BaseAPI<RequestAdapter>.Result<T> {
        guard let mockResponse = mockResponse as? BaseAPI<RequestAdapter>.Result<T> else { return .onFailure(nil) }
        self.uploadRequst = requst
        return mockResponse
    }
    
    override public func downloadFile<T: NetworkModel>(_ requst: NetworkRequest, destination: @escaping DownloadRequest.Destination, parameterEncoding: ParameterEncoding? = nil, automaticallyCancelling shouldAutomaticallyCancel: Bool = false, isEmptyResponse: Bool = false, model: T.Type, _ downloadProgress: (@MainActor (Double) -> ())? = nil, _ onDecodeFaluier: ((Data?) -> (DecodeResult<T>))? = nil) async -> BaseAPI<RequestAdapter>.Result<T> {
        guard let mockResponse = mockResponse as? BaseAPI<RequestAdapter>.Result<T> else { return .onFailure(nil) }
        self.requst = requst
        return mockResponse
    }
}
