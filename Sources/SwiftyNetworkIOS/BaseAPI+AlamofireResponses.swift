//
//  BaseAPI+AlamofireResponses.swift
//  SwiftyNetworkIOS
//
//  Created by Abdulrahman Ameen Hariri on 06/02/2025.
//
import Alamofire
import Foundation
import SwiftyJSON

extension BaseAPI {
    internal enum AlamofireResponses {
        case dataResponse(DataResponse<Data, AFError>)
        case downloadResponse(DownloadResponse<Data, AFError>)

        var error: AFError? {
            switch self {
            case .dataResponse(let dataResponse):
                return dataResponse.error
            case .downloadResponse(let downloadResponse):
                return downloadResponse.error
            }
        }

        var response: HTTPURLResponse? {
            switch self {
            case .dataResponse(let dataResponse):
                return dataResponse.response
            case .downloadResponse(let downloadResponse):
                return downloadResponse.response
            }
        }

        var data: Data? {
            switch self {
            case .dataResponse(let dataResponse):
                return dataResponse.data
            case .downloadResponse(let downloadResponse):
                return downloadResponse.value
            }
        }

        var result: Swift.Result<Data, AFError> {
            switch self {
            case .dataResponse(let dataResponse):
                return dataResponse.result
            case .downloadResponse(let downloadResponse):
                return downloadResponse.result
            }
        }
    }
}
