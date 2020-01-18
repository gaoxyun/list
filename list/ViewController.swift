//
//  ViewController.swift
//  list
//
//  Created by xiangyun on 2020/1/18.
//  Copyright © 2020 xiangyun. All rights reserved.
//

import UIKit
import MJRefresh

let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

func setupHeaderRefresh(_ target: AnyObject, action: Selector) -> MJRefreshNormalHeader {
    let headerRefresh = MJRefreshNormalHeader(refreshingTarget: target, refreshingAction: action)
    headerRefresh.lastUpdatedTimeLabel?.isHidden = true
    headerRefresh.stateLabel?.isHidden = true
    return headerRefresh
}

func setupFooterRefresh(_ target: AnyObject, action: Selector) -> MJRefreshAutoNormalFooter {
    let footerRefresh = MJRefreshAutoNormalFooter(refreshingTarget: target, refreshingAction: action)
    footerRefresh.setTitle("loading..", for: MJRefreshState.refreshing)
    footerRefresh.setTitle("pull up refresh data...", for: MJRefreshState.idle)
    footerRefresh.setTitle("no more data...", for: MJRefreshState.noMoreData)
    return footerRefresh
}

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    let service: INewsService = NewsService()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.mj_header = setupHeaderRefresh(self, action: #selector(refreshNews))
        tableView.mj_footer = setupFooterRefresh(self, action: #selector(loadMoreData))
        
        refreshNews()
    }


    // 刷新列表
    @objc private func refreshNews() {
        service.refreshNews { news in
            guard let news = news else {
                return
            }
            self.updateEndRefreshingStatus()
            self.newsList = news
            self.tableView.reloadData()
        }
    }

    @objc private func loadMoreData() {
        service.loadNextPage { news in
            guard let news = news else {
                self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                return
            }
            self.updateEndRefreshingStatus()
            
            if let lastId = self.newsList.last?.id, let _ = news.firstIndex(where: { item -> Bool in
                return item.id == lastId
            }) {
                // 数据如果已经存在表示已经加载完成
                self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                return
            }
            self.newsList = self.newsList + news
            self.tableView.reloadData()
        }
    }
    
    private func updateEndRefreshingStatus() {
        self.tableView.mj_header?.endRefreshing()
        self.tableView.mj_footer?.endRefreshing()
    }

    private var newsList: [NewsModel] = []
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! NewsCell
        let item = newsList[indexPath.row]
        cell.contentLabel.text = item.content
        cell.titleLabel.text = item.title
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
}

