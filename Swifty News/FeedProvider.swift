//
//  FeedProvider.swift
//  Swifty News
//
//  Created by Ali Karagoz on 03/02/16.
//  Copyright © 2016 Ali Karagoz. All rights reserved.
//

import Foundation
import RealmSwift

struct FeedProvider {
    
    static let urlString = "http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&num=100&q=http://feeds.feedburner.com/ProgrammableWeb"
    
    enum FeedProviderError: ErrorType {
        case InvalidData
        case InvalidJSON
    }
    
    static func fetchFeed(completion: ([Entry]?, error: FeedProviderError?)-> Void) {
        
        // Fetching some data from hacker news.
        let session = NSURLSession.sharedSession()
        let dataTask = session.dataTaskWithURL(NSURL(string: FeedProvider.urlString)!, completionHandler: { (data, reponse, error) -> Void in
            
            guard let data = data else {
                completion(nil, error: .InvalidData)
                return
            }
            
            let JSONEntries = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            
            if let JSONEntries = JSONEntries as? [String: AnyObject],
                let responseData = JSONEntries["responseData"] as? [String: AnyObject],
                let feed = responseData["feed"] as? [String: AnyObject],
                let items = feed["entries"] as? [[String: AnyObject]] {
                    var entries = [Entry]()
                    let realm = try! Realm()
                
                    for item in items{
                        let entry = Entry()
                        entry.title = (item["title"] as? String)!
                        entry.content = (item["content"] as? String)!
                    
                        let rawDate = item["publishedDate"] as? String
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "E, dd MMM yyyy HH:mm:ss zzzz"
                        let date = dateFormatter.dateFromString(rawDate!)
                        entry.publishedDate = date!
                        
       
                        entry.contentSnippet = (item["contentSnippet"] as? String)!
                        entry.link = (item["link"] as? String)!
                        
                        //                    entry.categories = (item["categories"] as? List<String>)!
                        try! realm.write {
                            realm.add(entry)
                        }
                        entries.append(entry)
                    }
                    completion(nil, error: nil)
            } else {
                completion(nil, error: .InvalidJSON)
            }
        })
        
        dataTask.resume()
    }
}