//
//  FeedProvider.swift
//  Swifty News
//
//  Created by Ali Karagoz on 03/02/16.
//  Copyright © 2016 Ali Karagoz. All rights reserved.
//

import Foundation

struct FeedProvider {
    
    static let urlString = "http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&num=30&q=http%3A%2F%2Fnews.ycombinator.com%2Frss%3F"
    
    enum FeedProviderError: ErrorType {
        case InvalidData
        case InvalidJSON
    }
    
    static func fetchFeed(completion: ([[String:AnyObject]]?, error: FeedProviderError?) -> Void) {
        
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
                let entries = feed["entries"] as? [[String: AnyObject]] {
                    completion(entries, error: nil)
            } else {
                completion(nil, error: .InvalidJSON)
            }
        })
        
        dataTask.resume()
    }
}