//
//  Category.swift
//  Swifty News
//
//  Created by Doron Katz on 5/2/16.
//  Copyright © 2016 Ali Karagoz. All rights reserved.
//

import RealmSwift

class Category: Object {
    dynamic var name = ""
    dynamic var entry: Entry?
}
