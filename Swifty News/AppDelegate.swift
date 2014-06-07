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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.backgroundColor = UIColor.whiteColor()
        
        // Base view controller.
        let tableViewController = AINewsTableViewController()
        let navigationController = UINavigationController(rootViewController: tableViewController);
        let splitViewController = UISplitViewController()
        splitViewController.viewControllers = [navigationController]
        self.window!.rootViewController = splitViewController;
        
        // Navigation bar customization.
        UINavigationBar.appearance().titleTextAttributes = [
            NSFontAttributeName : UIFont(name: "Avenir-Medium", size: 18.0),
            NSForegroundColorAttributeName: UIColor(white: 0.25, alpha: 1.0)
        ]
        
        self.window!.makeKeyAndVisible()
        return true
    }
    
}

