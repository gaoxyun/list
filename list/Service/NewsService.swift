//
//  xxService.swift
//  list
//
//  Created by xiangyun on 2020/1/18.
//  Copyright © 2020 xiangyun. All rights reserved.
//
import Alamofire
import Foundation

typealias NewsLoadCallback = (_ result: [NewsModel]?) -> ()

protocol INewsService {
    func loadNextPage(completion: @escaping NewsLoadCallback)
    func refreshNews(completion: @escaping NewsLoadCallback)
}

class NewsService: INewsService {
    private var totalAccount: Int = 0
    private var pageIndex: Int = 1
    private var usingCache: Bool = false
    private var dbOffset: Int = 0
    private let pageCount: Int = 10

// MARK: - protocol INewsService
    // 假设服务端列表数据始终有序
    // 第一次数据始终使用网络数据
    func refreshNews(completion: @escaping NewsLoadCallback) {
        totalAccount = 0
        pageIndex = 1
        dbOffset = 0
        loadPageFromServer(at: pageIndex, completion: completion)
    }

    func loadNextPage(completion: @escaping NewsLoadCallback) {
        pageIndex += 1
        
        // 使用本地缓存
        if usingCache {
            DBManager.instance.loadNews(at: dbOffset, count: pageCount) { newsModel in
                if let newsModel = newsModel, !newsModel.isEmpty {
                    self.dbOffset += newsModel.count
                    print("load from cache count: \(newsModel.count)")
                    completion(newsModel)
                } else {
                     completion(nil)
                }
            }
            return
        }
        
        loadPageFromServer(at: pageIndex, completion: completion)
    }
    
    private func loadPageFromServer(at index:Int, completion: @escaping NewsLoadCallback) {
        // 本地还不是最新 继续使用网络数据
        Alamofire.request(NewsRouter.newsTimeline(page: pageIndex))
            .responseDecodableObject { (response: DataResponse<GithubSearchRes>) in
                guard let res = response.result.value else {
                    completion(nil)
                    return
                }
                if index == 1 {
                    self.totalAccount = res.total_count
                }
                let list = res.items.map({ return NewsModel(id: $0.sha, content: $0.url, title: $0.name)})
                completion(list)
                
                // 缓存到本地
                let count = DBManager.instance.store(newsList: list)
                print("load from server count: \(list.count)")
                print("insert to db count: \(count)")
                // 当缓存到本地不需要缓存的时候，使用 本地cache
                if count == 0 && list.count > 0 {
                    self.usingCache = true
                    print("will using cache")
                }
                self.dbOffset += list.count
        }
    }
}
