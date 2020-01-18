//
//  DataRequest+Decodable.swift
//  list
//
//  Created by xiangyun on 2020/1/18.
//  Copyright © 2020 xiangyun. All rights reserved.
//

import Alamofire
import Foundation


extension DataRequest {

    private static func DecodableObjectSerializer<T: Decodable>(_ decoder: JSONDecoder) -> DataResponseSerializer<T> {
        return DataResponseSerializer { _, response, data, error in
            if let error = error {
                return .failure(error)
            }
            return DataRequest.decodeToObject(decoder: decoder, response: response, data: data)
        }
    }

    private static func decodeToObject<T: Decodable>(decoder: JSONDecoder, response: HTTPURLResponse?, data: Data?) -> Result<T> {
        let result = Request.serializeResponseData(response: response, data: data, error: nil)

        switch result {
        case .success(let value):
            do {
                let object = try decoder.decode(T.self, from: value)
                return .success(object)
            } catch {
                return .failure(error)
            }
        case .failure(let error): return .failure(error)
        }
    }

    @discardableResult
    public func responseDecodableObject<T: Decodable>(queue: DispatchQueue? = nil, decoder: JSONDecoder = JSONDecoder(), completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return validate().response(queue: queue, responseSerializer: DataRequest.DecodableObjectSerializer(decoder), completionHandler: completionHandler)
    }
}
