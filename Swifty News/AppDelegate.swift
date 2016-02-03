//
//  AppDelegate.swift
//  Swifty News
//
//  Created by Ali Karagoz on 07/06/14.
//  Copyright (c) 2014 Ali Karagoz. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.backgroundColor = UIColor.whiteColor()
        
        let tableViewController = NewsTableViewController()
        let navigationController = UINavigationController(rootViewController: tableViewController)
        let splitViewController = UISplitViewController()
        splitViewController.viewControllers = [navigationController]
        window!.rootViewController = splitViewController
        
        // Customization
        UINavigationBar.appearance().titleTextAttributes = [
            NSFontAttributeName : UIFont(name: "Avenir-Medium", size: 18.0)!,
            NSForegroundColorAttributeName : UIColor(white: 0.25, alpha: 1.0)
        ]
        
        window!.makeKeyAndVisible()
        return true
    }
}

