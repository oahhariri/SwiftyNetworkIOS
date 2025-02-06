//
//  Session+Ext.swift
//  SwiftyNetworkIOS
//
//  Created by Abdulrahman Hariri on 18/02/1444 AH.
//

import Alamofire
import Foundation

extension Session {
    func request<RequestAdapter: APIRequestAdapter>(_ requst: NetworkRequest, parameterEncoding: ParameterEncoding? = nil, requestAdapter: RequestAdapter) -> DataRequest {
        var encoding: ParameterEncoding = JSONEncoding.default

        if let parameterEncoding {
            encoding = parameterEncoding
        } else {
            if requst.endpoint.method == .get ||
                requst.endpoint.method == .delete ||
                requst.endpoint.method == .head
            {
                encoding = URLEncoding(destination: URLEncoding.default.destination, arrayEncoding: .noBrackets, boolEncoding: URLEncoding.default.boolEncoding)
            }
        }

        return request(requst.endpoint.path, method: requst.endpoint.method, parameters: requst.parameters, encoding: encoding, headers: requst.header, interceptor: RequestInterceptor(info: requst, requestAdapter: requestAdapter))
    }

    func uploadMultipart<RequestAdapter: APIRequestAdapter>(_ requst: NetworkUploadRequest, requestAdapter: RequestAdapter) -> UploadRequest {
        return upload(multipartFormData: requst.data, to: requst.endpoint.path, method: requst.endpoint.method, headers: requst.header,
                      interceptor: RequestInterceptor(info: requst, requestAdapter: requestAdapter))
    }

    func downloadFile<RequestAdapter: APIRequestAdapter>(url: URL, requst: NetworkRequest, parameterEncoding: ParameterEncoding? = nil, requestAdapter: RequestAdapter, destination: @escaping DownloadRequest.Destination) -> DownloadRequest {
        var encoding: ParameterEncoding = JSONEncoding.default

        if let parameterEncoding {
            encoding = parameterEncoding
        } else {
            if requst.endpoint.method == .get ||
                requst.endpoint.method == .delete ||
                requst.endpoint.method == .head
            {
                encoding = URLEncoding(destination: URLEncoding.default.destination, arrayEncoding: .noBrackets, boolEncoding: URLEncoding.default.boolEncoding)
            }
        }

        return download(url, method: requst.endpoint.method, parameters: requst.parameters, encoding: encoding, headers: requst.header, interceptor: RequestInterceptor(info: requst, requestAdapter: requestAdapter), to: destination)
    }
}
