//
//  NewsTableViewController.swift
//  Swifty News
//
//  Created by Ali Karagoz on 07/06/14.
//  Copyright (c) 2014 Ali Karagoz. All rights reserved.
//

import UIKit
import SafariServices

class NewsTableViewController: UITableViewController {
    
    var news = [[String: AnyObject]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Swifty News"
        tableView.registerClass(TableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)
        
        FeedProvider.fetchFeed { entries, error in
            if let entries = entries {
                self.news = entries
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return news.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TableViewCell
        let entry = news[indexPath.row]
        if let title = entry["title"] as? String, link = entry["link"] as? String {
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = link
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let entry = news[indexPath.row]
        if let title = entry["title"] as? String, link = entry["link"] as? String {
            let safariViewController = SFSafariViewController(URL: NSURL(string: link)!)
            safariViewController.title = title
            splitViewController?.showDetailViewController(safariViewController, sender: self)
        }
    }
    
}
