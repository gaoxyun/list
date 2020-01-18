//
//  Model.swift
//  list
//
//  Created by xiangyun on 2020/1/18.
//  Copyright © 2020 xiangyun. All rights reserved.
//

import Foundation

struct NewsModel: Codable {
    let id: String
    let content: String
    let title: String
}


// 使用Github 返回数据代替
struct GithubItem: Codable {
    let name: String
    let sha: String
    let url: String
}

struct GithubSearchRes: Codable {
    let total_count: Int
    let items: [GithubItem]
}
