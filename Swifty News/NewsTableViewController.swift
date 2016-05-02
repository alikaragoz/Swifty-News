//
//  NewsTableViewController.swift
//  Swifty News
//
//  Created by Ali Karagoz on 07/06/14.
//  Copyright (c) 2014 Ali Karagoz. All rights reserved.
//

import UIKit
import SafariServices
import RealmSwift

class NewsTableViewController: UITableViewController {
    
    let news = try! Realm().objects(Entry).sorted("publishedDate")
    var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Swifty News"
        tableView.registerClass(TableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)
        
        self.refresh()
        FeedProvider.fetchFeed {_, error in
            guard (error == nil) else{
                print("We have an error ", error.debugDescription)
                return
            }
        }
    }
    
    private func refresh(){
        self.notificationToken = news.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {
            case .Initial:
                // Results are now populated and can be accessed without blocking the UI
                self.tableView.reloadData()
                break
            case .Update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the TableView
                self.tableView.beginUpdates()
                self.tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: 0) },
                    withRowAnimation: .Automatic)
                self.tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: 0) },
                    withRowAnimation: .Automatic)
                self.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: 0) },
                    withRowAnimation: .Automatic)
                self.tableView.endUpdates()
                break
            case .Error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
                break
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
