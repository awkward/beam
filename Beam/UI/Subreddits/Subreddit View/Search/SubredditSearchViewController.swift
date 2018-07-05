//
//  SubredditSearchViewController.swift
//  beam
//
//  Created by Robin Speijer on 29-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

class SubredditSearchViewSearchController: UISearchController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return DisplayModeValue(UIStatusBarStyle.default, darkValue: UIStatusBarStyle.lightContent)
    }
}

class SubredditSearchViewController: BeamTableViewController, SubredditTabItemViewController {
    
    var titleView = SubredditTitleView.titleViewWithSubreddit(nil)
    
    weak var subreddit: Subreddit? {
        didSet {
            if let subreddit = self.subreddit, let displayName = subreddit.displayName, subreddit.isPrepopulated == false {
                self.searchController.searchBar.placeholder = AWKLocalizedString("search-subreddit-placeholder").replacingOccurrences(of: "[SUBREDDIT]", with: displayName)
            } else {
                self.searchController.searchBar.placeholder = AWKLocalizedString("search-reddit-placeholder")
            }
        }
    }
    
    var requestTimer: Timer?
    
    lazy var resultsController: SubredditSearchResultsViewController = {
        let resultViewController = self.storyboard!.instantiateViewController(withIdentifier: "subredditSearchResults") as! SubredditSearchResultsViewController
        resultViewController.subreddit = self.subreddit
        return resultViewController
    }()
    
    lazy var searchController: SubredditSearchViewSearchController = {
        let controller = SubredditSearchViewSearchController(searchResultsController: self.resultsController)
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.navigationController?.navigationBar as? BeamNavigationBar)?.showBottomBorder = false
        
        self.tableView.scrollsToTop = false
        
        //Fix for the black screen bug
        self.definesPresentationContext = true
        
        self.searchController.searchBar.delegate = self
        self.searchController.searchResultsUpdater = self.resultsController
        self.searchController.searchBar.searchBarStyle = UISearchBarStyle.default
        
        self.resultsController.customNavigationController = self.navigationController
        
        self.updateNavigationItem()
        
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.searchController = self.searchController
        
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let searchBar = self.searchController.searchBar
        searchBar.applyBeamBarStyle()
    }

}

// MARK: - UISearchBarDelegate
extension SubredditSearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.resultsController.startFetching(searchBar.text)
    }
    
}
