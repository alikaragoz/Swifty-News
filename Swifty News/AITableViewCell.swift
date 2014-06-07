//
//  AITableViewCell.swift
//  Swifty News
//
//  Created by Ali Karagoz on 07/06/14.
//  Copyright (c) 2014 Ali Karagoz. All rights reserved.
//

import UIKit

class AITableViewCell: UITableViewCell {

    init(style: UITableViewCellStyle, reuseIdentifier: String) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
        
        textLabel.font = UIFont(name: "Avenir-Light", size: 13.0)
        textLabel.numberOfLines = 0
        
        detailTextLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
        detailTextLabel.font = UIFont(name: "Avenir-Light", size: 13.0)
        
        accessoryType = .DisclosureIndicator;
    }

}
