//
//  Router.swift
//  list
//
//  Created by xiangyun on 2020/1/18.
//  Copyright © 2020 xiangyun. All rights reserved.
//

import Alamofire
import Foundation

enum NewsRouter {
    case newsTimeline(page: Int)
    
    var method: HTTPMethod {
        switch self {
        case .newsTimeline:
            return .get
        }
    }

    var path: String {
        switch self {
            case .newsTimeline:
            return "https://api.github.com/search/code"
        }
    }
}

extension NewsRouter: URLRequestConvertible {
    func asURLRequest() throws -> URLRequest {

        switch self {
        case .newsTimeline(let page):
            var urlRequest = URLRequest(url: URL(string: path)!)
            urlRequest.httpMethod = method.rawValue
            // 使用github 搜索接口mock分页接口
            urlRequest = try URLEncoding.queryString.encode(urlRequest, with: ["q":"swift+user:apple", "page": page])
            return urlRequest
        }
    }
}
