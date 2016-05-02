//
//  Entry.swift
//  Swifty News
//
//  Created by Doron Katz on 5/2/16.
//  Copyright © 2016 Ali Karagoz. All rights reserved.
//

import RealmSwift

class Entry: Object {
    dynamic var title = ""
    dynamic var author = ""
    dynamic var link = ""
    dynamic var publishedDate = NSDate(timeIntervalSince1970: 1)
    dynamic var contentSnippet = ""
    dynamic var content = ""
    let categories = List<Category>()
}
