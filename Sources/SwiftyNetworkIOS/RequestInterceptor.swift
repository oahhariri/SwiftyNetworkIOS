//
//  RequestInterceptor.swift
//  SwiftyNetworkIOS
//
//  Created by Abdulrahman Hariri on 18/02/1444 AH.
//
import Alamofire
import Foundation
import SwiftyJSON

internal final class RequestInterceptor<RequestAdapter: APIRequestAdapter>: Alamofire.RequestInterceptor {
    private let requsetInfo: NetworkRequest?
    private let uploadRequestInfo: NetworkUploadRequest?

    private let requestAdapter: RequestAdapter
    private let endpointInfo: EndpointInfo

    internal init(info: NetworkRequest, requestAdapter: RequestAdapter) {
        self.requsetInfo = info
        self.uploadRequestInfo = nil
        self.requestAdapter = requestAdapter
        self.endpointInfo = info.endpoint
    }

    internal init(info: NetworkUploadRequest, requestAdapter: RequestAdapter) {
        self.uploadRequestInfo = info
        self.requsetInfo = nil
        self.requestAdapter = requestAdapter
        self.endpointInfo = info.endpoint
    }

    internal func headers() -> HTTPHeaders {
        return requsetInfo?.header ?? uploadRequestInfo?.header ?? HTTPHeaders()
    }

    internal func parameters() -> Parameters {
        return requsetInfo?.parameters ?? Parameters()
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        Task { [weak self] in
            guard let self else { return }
            
            if let afError = error.asAFError, afError.isRequestRetryError {
                completion(.doNotRetryWithError(error))
                return
            }

            guard request.retryCount < 1 else {
                completion(.doNotRetryWithError(error))
                return
            }

            guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
                completion(requestAdapter.retry(networkEndpoints: requsetInfo?.networkEndpoints ?? uploadRequestInfo?.networkEndpoints, endpointInfo, request, error, isAfterRefresh: false))
                return
            }

            Logger.shared.error("attempt to retry request url: [\(endpointInfo.path)] due token issue,\n parameters:\n \(JSON(parameters())),\n headers: \n \(headers())")

            guard await requestAdapter.refreshToken(networkEndpoints: requsetInfo?.networkEndpoints ?? uploadRequestInfo?.networkEndpoints, requsetInfo: endpointInfo) == nil else {
                Logger.shared.error("request url: [\(endpointInfo.path)] failed due token issue .. should sginOut,\n parameters:\n \(JSON(parameters())),\n headers: \(headers())")
                completion(requestAdapter.retry(networkEndpoints: requsetInfo?.networkEndpoints ?? uploadRequestInfo?.networkEndpoints, endpointInfo, request, error, isAfterRefresh: true))
                return
            }

            Logger.shared.info("request url: [\(endpointInfo.path)] will retry after token Refresh ,\n parameters:\n \(JSON(parameters())),\n headers: \n \(headers())")
            completion(.retry)
        }
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        requestAdapter.adapt(networkEndpoints: requsetInfo?.networkEndpoints ?? uploadRequestInfo?.networkEndpoints, endpointInfo, urlRequest) { [weak self] urlRequest in
            guard let urlRequest else {
                completion(.failure(CustomError(message: nil)))
                return
            }

            guard let self else {
                completion(.success(urlRequest))
                return
            }
            Logger.shared.debug("will send requst to url: [\(self.endpointInfo.path)],\n parameters:\n \(JSON(self.parameters())),\n headers: \n \(urlRequest.headers)")

            completion(.success(urlRequest))
        }
    }
}

struct CustomError: Error {
    var message: String?
    var code: Int

    init(message: String?, code: Int = -1) {
        self.message = message
        self.code = code
    }
}
