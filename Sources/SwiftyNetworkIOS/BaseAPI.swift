//
//  BaseAPI.swift
//  SwiftyNetworkIOS
//
//  Created by Abdulrahman Hariri on 18/02/1444 AH.
//
import Alamofire
import Foundation
import SwiftyJSON

public protocol APIRequestAdapter {
    associatedtype APIResponseStatus
    /// add custome httpRespnes handler ,
    func requestValidator(networkEndpoints:NetworkEndpoints?,
                          _ requsetInfo: EndpointInfo,
                          _ data: Data?,
                          _ httpRespnes: HTTPURLResponse?,
                          _ failuerReson: String?,
                          _ afError: AFError?) -> APIResponseStatus?
    
    func refreshToken(networkEndpoints:NetworkEndpoints?,
                      requsetInfo: EndpointInfo) async -> APIResponseStatus?
    
    func adapt(networkEndpoints:NetworkEndpoints?,
               _ requsetInfo: EndpointInfo,
               _ urlRequest: URLRequest,
               completion: @escaping (URLRequest?) -> Void)
    
    func retry(networkEndpoints:NetworkEndpoints?,
               _ requsetInfo: EndpointInfo,
               _ AFrequest: Request,
               _ error: Error,
               isAfterRefresh: Bool) -> RetryResult
}

public enum DecodeResult<T> {
    case onSuccess(T?, Data?)
    case onFailure(_ faliuerReason: String)
}

public class BaseAPI<RequestAdapter: APIRequestAdapter> {
    internal enum ResponseSuccessStatus {
        case error
        case successWithEmpty
        case success
    }
    
    public enum Result<T> {
        case onSuccess(T?, _ data: Data?)
        case onFailure(RequestAdapter.APIResponseStatus?)
        
        public var isSuccess: Bool {
            switch self {
            case .onSuccess:
                return true
            case .onFailure:
                return false
            }
        }
        
        public var isFailure: Bool {
            switch self {
            case .onSuccess:
                return false
            case .onFailure:
                return true
            }
        }
        
        public var model: T? {
            switch self {
            case .onSuccess(let model, _):
                return model
            case .onFailure:
                return nil
            }
        }
        
        public var data: Data? {
            switch self {
            case .onSuccess(_, let data):
                return data
            case .onFailure:
                return nil
            }
        }
        
        public var errorModel: RequestAdapter.APIResponseStatus? {
            switch self {
            case .onSuccess:
                return nil
            case .onFailure(let error):
                return error
            }
        }
    }
    
    private var baseUrl: String
    private(set) var headers: HTTPHeaders
    let requestAdapter: RequestAdapter
    
    private let session: Session
    
    public init(baseUrl: String,
                headers: HTTPHeaders = [],
                urlSessionConfiguration: URLSessionConfiguration? = nil,
                logLevel: LoggerLevel = .none, requestAdapter: RequestAdapter) {
        
        self.headers = headers
        self.requestAdapter = requestAdapter
        self.baseUrl = baseUrl
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        
        session = Session(configuration: urlSessionConfiguration ?? configuration)
        
        Logger.shared.logLevel = logLevel
        Logger.shared.info("initialized with baseUrl = [\(baseUrl)]]")
    }
    
    public func updateBaseUrl(baseUrl: String) {
        self.baseUrl = baseUrl
        Logger.shared.info("[updated] baseUrl = [\(baseUrl)]]")
    }
    
    public func request<T: NetworkModel>(_ requst: NetworkRequest,
                                         parameterEncoding: ParameterEncoding? = nil,
                                         automaticallyCancelling shouldAutomaticallyCancel: Bool = false,
                                         isEmptyResponse:Bool = false,
                                         model: T.Type,
                                         _ onDecodeFaluier: ((Data?) -> (DecodeResult<T>))? = nil) async -> Result<T> {
        
        let responseData = await makeRequest(requst,
                                             parameterEncoding: parameterEncoding,
                                             automaticallyCancelling: shouldAutomaticallyCancel,
                                             isEmptyResponse:isEmptyResponse,
                                             model: model,
                                             onDecodeFaluier)
        
        return await handelResones(requst.networkEndpoints, result: .dataResponse(responseData), endpoint: requst.endpoint, model: model, onDecodeFaluier)
    }
    
    public func requestWithCookies<T: NetworkModel>(_ requst: NetworkRequest,
                                                    parameterEncoding: ParameterEncoding? = nil,
                                                    automaticallyCancelling shouldAutomaticallyCancel: Bool = false,
                                                    isEmptyResponse:Bool = false,
                                                    model: T.Type,
                                                    _ onDecodeFaluier: ((Data?) -> (DecodeResult<T>))? = nil) async -> (result:Result<T>,cookies:[HTTPCookie]) {
        
        let responseData = await makeRequest(requst,
                                             parameterEncoding: parameterEncoding,
                                             automaticallyCancelling: shouldAutomaticallyCancel,
                                             isEmptyResponse:isEmptyResponse,
                                             model: model,
                                             onDecodeFaluier)
        
        var cookies  = [HTTPCookie]()
        let result : AlamofireResponses = .dataResponse(responseData)
        
        if let url = URL(string: requst.endpoint.path) , let allHeaderFields = result.response?.allHeaderFields as? [String: String] {
            cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: url)
        }
        
        
        let respone = await handelResones(requst.networkEndpoints, result: .dataResponse(responseData), endpoint: requst.endpoint, model: model, onDecodeFaluier)
        
        return (result:respone,cookies:cookies)
    }
    
    private func makeRequest<T: NetworkModel>(_ requst: NetworkRequest,
                                              parameterEncoding: ParameterEncoding? = nil,
                                              automaticallyCancelling shouldAutomaticallyCancel: Bool = false,
                                              isEmptyResponse:Bool = false,
                                              model: T.Type,
                                              _ onDecodeFaluier: ((Data?) -> (DecodeResult<T>))? = nil) async -> DataResponse<Data, AFError> {
        
        let requst = requstBuilder(requst)
        
        
        let emptyResponseCodes:Set<Int> = isEmptyResponse ? Set<Int>(200...299) : DataResponseSerializer.defaultEmptyResponseCodes
        
        let responseData = await session.request(requst, parameterEncoding: parameterEncoding, requestAdapter: requestAdapter)
            .cURLDescription { cURLDescription in
                Logger.shared.debug("request cURL: \n \(cURLDescription)")
            }
            .validate()
            .serializingData(automaticallyCancelling: shouldAutomaticallyCancel,emptyResponseCodes: emptyResponseCodes)
            .response
        
        
        return responseData
    }
    
    
    public func uploadMultipart<T: NetworkModel>(_ requst: NetworkUploadRequest,
                                                 automaticallyCancelling shouldAutomaticallyCancel: Bool = false,
                                                 isEmptyResponse:Bool = false,
                                                 model: T.Type,
                                                 _ uploadProgress: (@MainActor (Double) -> ())? = nil,
                                                 _ onDecodeFaluier: ((Data?) -> (DecodeResult<T>))? = nil) async -> Result<T> {
        
        let requst = requstBuilder(requst)
        
        Logger.shared.debug("will upload Data to url: [\(requst.endpoint.path)] ")
        
        let emptyResponseCodes:Set<Int> = isEmptyResponse ? Set<Int>(200...299) : DataResponseSerializer.defaultEmptyResponseCodes
        
        let responseData = await session.uploadMultipart(requst, requestAdapter: self.requestAdapter)
            .validate()
            .cURLDescription { cURLDescription in
                Logger.shared.debug("request cURL: \n \(cURLDescription)")
            }
            .uploadProgress { progress in
                Task {
                    await uploadProgress?(progress.fractionCompleted)
                }
            }
            .serializingData(automaticallyCancelling: shouldAutomaticallyCancel, emptyResponseCodes: emptyResponseCodes)
            .response
        
        return await handelResones(requst.networkEndpoints, result: .dataResponse(responseData), endpoint: requst.endpoint, model: model, onDecodeFaluier)
    }
    
    public func downloadFile<T: NetworkModel>(_ requst: NetworkRequest,
                                              destination: @escaping DownloadRequest.Destination,
                                              parameterEncoding: ParameterEncoding? = nil,
                                              automaticallyCancelling shouldAutomaticallyCancel: Bool = false,
                                              isEmptyResponse:Bool = false, model: T.Type,
                                              _ downloadProgress: (@MainActor (Double) -> ())? = nil,
                                              _ onDecodeFaluier: ((Data?) -> (DecodeResult<T>))? = nil) async -> Result<T> {
        let requst = requstBuilder(requst)
        
        Logger.shared.debug("will Dwonload Data From url: [\(requst.endpoint.path)]")
        
        guard let downloadUrl = URL(string: requst.endpoint.path) else { return .onFailure(nil) }
        
        let emptyResponseCodes:Set<Int> = isEmptyResponse ? Set<Int>(200...299) : DataResponseSerializer.defaultEmptyResponseCodes
        
        let responseData = await session.downloadFile(url: downloadUrl, requst: requst, parameterEncoding: parameterEncoding, requestAdapter: self.requestAdapter, destination: destination)
            .validate()
            .cURLDescription { cURLDescription in
                Logger.shared.debug("request cURL: \n \(cURLDescription)")
            }
            .downloadProgress { progress in
                Task {
                    await downloadProgress?(progress.fractionCompleted)
                }
            }
            .serializingData(automaticallyCancelling: shouldAutomaticallyCancel,emptyResponseCodes: emptyResponseCodes)
            .response
        
        return await handelResones(requst.networkEndpoints, result: .downloadResponse(responseData), endpoint: requst.endpoint, model: model, onDecodeFaluier)
    }
    
}

//MARK: - Handel Resones

extension BaseAPI {
    
    private func handelResones<T: NetworkModel>(_ networkEndpoints:NetworkEndpoints?,
                                                result: AlamofireResponses,
                                                endpoint: EndpointInfo,
                                                model: T.Type,
                                                _ onDecodeFailure: ((Data?) -> (DecodeResult<T>))? = nil) async -> Result<T> {
        switch result.result {
        case .success(let data):
            
            Logger.shared.debug("Resones from requst url: [\(endpoint.path)],\n statusCode: \(result.response?.statusCode ?? -1),\n Resones:\n  \(JSON(data))")
            return await ckeckResponseOnSuccess(data: data, networkEndpoints, result: result, endpoint: endpoint, model: model, onDecodeFailure)
            
        case .failure(let error):
            
            let failuierReson = "Error ouccerd for Requst url: [\(endpoint.path)],\n Model: [\(model)] ,\n statusCode: [\(result.response?.statusCode ?? -1)],\n AFError: [\(error)],\n Resones:  [\(JSON(result.data ?? Data()))]"
            
            Logger.shared.error(failuierReson)
            return .onFailure(requestAdapter.requestValidator(networkEndpoints: networkEndpoints,endpoint, result.data, result.response, failuierReson, error))
        }
    }
    
    private func ckeckResponseOnSuccess<T: NetworkModel >(data: Data,
                                                          _ networkEndpoints: NetworkEndpoints?,
                                                          result: AlamofireResponses,
                                                          endpoint: EndpointInfo,
                                                          model: T.Type,
                                                          _ onDecodeFailure: ((Data?) -> (DecodeResult<T>))? = nil) async -> Result<T> {
        
        guard ckeckResponse(result.response) else {
            Logger.shared.debug("Requst url: [\(endpoint.path)]: will be checked on [RequestAdapter] with status code: [\(result.response?.statusCode ?? -1)]")
            return .onFailure(requestAdapter.requestValidator(networkEndpoints: networkEndpoints, endpoint, data, result.response, "", result.error))
        }
        
        switch checkEmptyResponse(data, result.response) {
        case .success:
            
            return await handelOnSuccessResones(data: data, networkEndpoints, result: result, endpoint: endpoint, model: model, onDecodeFailure)
            
        case .successWithEmpty:
            Logger.shared.info("Requst success With [Empty or null] Response to url: [\(endpoint.path)],\n Model: [\(model)],\n StatusCode: [\(result.response?.statusCode ?? -1)]")
            return .onSuccess(nil, data)
        case .error:
            
            let failuierReson = "Requst url: [\(endpoint.path)]: will be checked on [RequestAdapter] with unexpected Error -- Model: [\(model)], StatusCode: [\(result.response?.statusCode ?? -1)]"
            
            Logger.shared.debug(failuierReson)
            return .onFailure(requestAdapter.requestValidator(networkEndpoints: networkEndpoints,endpoint, data, result.response, failuierReson, result.error))
        }
        
    }
    
    private func handelOnSuccessResones <T: NetworkModel >(data: Data,
                                                           _ networkEndpoints: NetworkEndpoints?,
                                                           result: AlamofireResponses,
                                                           endpoint: EndpointInfo,
                                                           model: T.Type,
                                                           _ onDecodeFailure: ((Data?) -> (DecodeResult<T>))? = nil) async -> Result<T> {
        
        let decodeResult = decode(data, endpoint: endpoint, of: model, onDecodeFailure)
        
        switch decodeResult {
        case .onSuccess(let modelResult, let data):
            Logger.shared.info("Requst succss to url: [\(endpoint.path)],\n Model: [\(model)],\n StatusCode: [\(result.response?.statusCode ?? -1)]")
            
            return .onSuccess(modelResult, data)
            
        case .onFailure(let failuerReason):
            Logger.shared.debug("Requst url: [\(endpoint.path)], will be checked on [RequestAdapter] with Error while decode to [\(model)] , StatusCode: [\(result.response?.statusCode ?? -1)]")
            return .onFailure(requestAdapter.requestValidator(networkEndpoints: networkEndpoints,endpoint, data, result.response, failuerReason, result.error))
        }
        
    }
    
    private func checkEmptyResponse(_ data: Data?,
                                    _ httpRespnes: HTTPURLResponse?) -> ResponseSuccessStatus {
        
        guard let statusCode = httpRespnes?.statusCode else { return .error }
        guard (200 ..< 300).contains(statusCode) else { return .error }
        
        guard let data else { return .successWithEmpty }
        return JSON(data).isEmpty ? .successWithEmpty : .success
    }
    
    private func ckeckResponse(_ response: HTTPURLResponse?) -> Bool {
        guard let code = response?.statusCode else { return false }
        
        switch code {
        case 200 ... 299:
            return true
        default:
            return false
        }
    }
    
}

//MARK: - Handel Decode
extension BaseAPI {
    
    private func decode<T: NetworkModel>(_ data: Data,
                                         endpoint: EndpointInfo,
                                         of type: T.Type,
                                         _ onDecodeFailure: ((Data?) -> (DecodeResult<T>))? = nil) -> DecodeResult<T> {
        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode(T.self, from: data)
            
            return .onSuccess(model, data)
            
        } catch let error {
            if let customDecodeResult = customDecode(data, onDecodeFailure) {
                return customDecodeResult
            }
            let faliuerReason = "Decode Error of Model [\(type)] Requst \(endpoint.path), Decode Error Info = \(error)"
            
            Logger.shared.error(faliuerReason)
            return .onFailure(faliuerReason)
        }
    }
    
    private func customDecode<T: NetworkModel>(_ data: Data,
                                               _ onDecodeFailure: ((Data?) -> (DecodeResult<T>))? = nil) -> DecodeResult<T>? {
        guard let onDecodeFailure else { return nil }
        
        let result = onDecodeFailure(data)
        
        switch result {
        case .onSuccess(let model, let data):
            return .onSuccess(model, data)
        default:
            return nil
        }
    }
}


//MARK: - Handel Helpers

extension BaseAPI {
    
    private func requstBuilder(_ requst: NetworkRequest) -> NetworkRequest {
        let baseUrl = requst.endpoint.customBaseUrl ?? baseUrl
        let endpoint = EndpointInfo(baseUrl + requst.endpoint.path, requst.endpoint.method)
        return .init(requst.networkEndpoints,endpoint: endpoint, header: addShredHeaders(headrs: requst.header), parameters: requst.parameters)
    }
    
    private func requstBuilder(_ requst: NetworkUploadRequest) -> NetworkUploadRequest {
        let baseUrl = requst.endpoint.customBaseUrl ?? baseUrl
        let endpoint = EndpointInfo(baseUrl + requst.endpoint.path, requst.endpoint.method)
        return .init(requst.networkEndpoints,endpoint: endpoint, header: addShredHeaders(headrs: requst.header), data: requst.data)
    }
    
    private func addShredHeaders(headrs: HTTPHeaders) -> HTTPHeaders {
        var sharedHeaders = self.headers
        
        for header in headrs {
            sharedHeaders.add(header)
        }
        
        return sharedHeaders
    }
}
