//
//  SubredditTabItemViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 09-06-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

/// SubredditTabItemViewController should be implemented by all ViewControllers in the SubredditTabBarController.
/// This protocol will make sure the required properties are available, will add the `subredditTabBarController` property and
/// has a method to take care of updating the navigation item with the correct title and buttons
protocol SubredditTabItemViewController {
    
    /// The subreddit, this property is set by the SubredditTabBarController. When this property changes,
    /// the navigation item should be updated by calling `updateNavigationItem()`.
    /// This is also the place to update queries
    var subreddit: Subreddit? { get set }
    
    /// The `titleView` used when updating the `navigationItem`. This property should return a `SubredditTitleView` or subclass of `SubredditTitleView`.
    var titleView: SubredditTitleView { get }
    
    /// This represents the SubredditTabBarController if the viewController is in a SubredditTabBarController
    var subredditTabBarController: SubredditTabBarController? { get }
    
    /// This method will update the navigation item of the view controller with the approriate buttons.
    /// This method should be called manually in `viewDidLoad()` and the setter of `subreddit`. Or other times when the titleView or
    /// items need updating (like upon subscribing/unsubscribing)
    func updateNavigationItem()
}

extension SubredditTabItemViewController where Self: UIViewController {
    
    weak var subredditTabBarController: SubredditTabBarController? {
        return self.tabBarController as? SubredditTabBarController
    }
    
    func updateNavigationItem() {
        //Update the title view subreddit
        self.titleView.subreddit = self.subreddit
        self.layoutTitleView()
        //Always set the titleView again, otherwise the size doesn't update
        self.navigationItem.titleView = self.titleView
        
        //Update the navigation items
        self.configureRightBarButtonItems()
            
        self.configureLeftBarButtonItems()
        
    }
    
    fileprivate func layoutTitleView() {
        var frame = self.titleView.frame
        
        let size = self.titleView.systemLayoutSizeFitting(self.navigationController?.navigationBar.frame.size ?? CGSize.zero)
        frame.size = size
        
        self.titleView.frame = frame
    }
    
    fileprivate func configureLeftBarButtonItems() {
        guard let subredditTabBarController = self.subredditTabBarController else {
            return
        }
        let closeItem = UIBarButtonItem(image: UIImage(named: "navigationbar_close"), style: UIBarButtonItemStyle.plain, target: subredditTabBarController, action: #selector(SubredditTabBarController.closeTapped(_:)))
        self.navigationItem.leftBarButtonItem = closeItem
    }
    
    fileprivate func configureRightBarButtonItems() {
        if self.subreddit?.isPrepopulated == true {
            self.navigationItem.rightBarButtonItem = nil
            return
        }
        guard let subredditTabBarController = self.subredditTabBarController else {
            return
        }
        if self.subreddit is Multireddit {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "copy_multireddit"), style: UIBarButtonItemStyle.plain, target: subredditTabBarController, action: #selector(SubredditTabBarController.copyMultireddit))
            return
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "compose_icon"), style: UIBarButtonItemStyle.plain, target: subredditTabBarController, action: #selector(SubredditTabBarController.composeTapped(_:)))
    }
}
