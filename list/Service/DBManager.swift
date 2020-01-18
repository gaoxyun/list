//
//  CacheManager.swift
//  list
//
//  Created by xiangyun on 2020/1/18.
//  Copyright © 2020 xiangyun. All rights reserved.
//

import Foundation
import FMDB

protocol IDBManager {
    func loadNews(at offset: Int, count: Int, completion: @escaping NewsDBLoadCallback)
    func store(newsList: [NewsModel]) -> Int
}

typealias NewsDBLoadCallback = (_ result: [NewsModel]?) -> ()
let NEWS_LIST_TABLE = "news_list_table"

class DBManager: IDBManager {
    
    static var instance: IDBManager {
        return mgr
    }
    
    init() {
        let documentPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        let path = "\(documentPath)/\(newsDBName)"
        print(path)
        
        // TODO 容错
        dbQueue = FMDatabaseQueue(path: path)!
        createNewsListTable(NEWS_LIST_TABLE)
    }
 
// MARK: - protocol IDBManager
    func loadNews(at offset: Int, count: Int, completion: @escaping NewsDBLoadCallback) {

        // 按时间倒序排列
        let sql = "SELECT * FROM \(NEWS_LIST_TABLE) ORDER BY createTime DESC LIMIT \(offset), \(count)"
        dbQueue.inDatabase { db in
            do {
                let rs = try db.executeQuery(sql, values: nil)
                var newsList = [NewsModel]()
                while rs.next() {
                    if let newsJsonString = rs.string(forColumn: "news") {
                        let jsonData = newsJsonString.data(using: .utf8)!
                        let news = try JSONDecoder().decode(NewsModel.self, from: jsonData)
                        newsList.append(news)
                    }
                }
                DispatchQueue.main.async {
                    if newsList.isEmpty {
                        completion(nil)
                    } else {
                        completion(newsList)
                    }
                }
            } catch {
                print(error)
            }
        }
    }

    func store(newsList: [NewsModel]) -> Int {
        let sql = "INSERT INTO \(NEWS_LIST_TABLE) (id, news) VALUES (?, ?)"
        var insertCount = 0
        dbQueue.inTransaction { (db, rollback) in
            do {
                for news in newsList {
                    let jsonData = try JSONEncoder().encode(news)
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    let res = try db.executeQuery("SELECT COUNT(1) FROM \(NEWS_LIST_TABLE) WHERE id='\(news.id)'", values: nil)
                    if res.next() && res.int(forColumnIndex: 0) == 0 {
                        insertCount += 1
                        try db.executeUpdate(sql, values: [news.id, jsonString, jsonString])
                    }
                }
            } catch {
                rollback.pointee = true
                print(error)
            }
        }
        return insertCount
    }
    
// MARK: - private function
    fileprivate func createNewsListTable(_ tbname: String) {
        
        let sql = "CREATE TABLE IF NOT EXISTS \(tbname) ( \n" +
            "id TEXT NOT NULL PRIMARY KEY, \n" +
            "news TEXT, \n" +
            "createTime VARCHAR(30) DEFAULT (datetime('now', 'localtime')) \n" +
        ");"
        
        dbQueue.inDatabase { (db) in
            if db.executeStatements(sql) == true {
                print("success")
            } else {
                print("failed")
            }
        }
    }

// MARK: - private data
    private static let mgr = DBManager()
    private let newsDBName = "news.db"
    private let dbQueue: FMDatabaseQueue
}
