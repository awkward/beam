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
        guard let storyboard = self.storyboard else {
            fatalError("Cannot find storyboard for subreddit search")
        }
        guard let resultViewController = storyboard.instantiateViewController(withIdentifier: "subredditSearchResults") as? SubredditSearchResultsViewController else {
            fatalError("Cannot find subreddit search results scene in storyboard")
        }
        resultViewController.subreddit = subreddit
        return resultViewController
    }()
    
    lazy var searchController = UISearchController(searchResultsController: self.resultsController)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.scrollsToTop = false
        
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = resultsController
        resultsController.customNavigationController = navigationController
        
        self.updateNavigationItem()
        
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
    }

}

// MARK: - UISearchBarDelegate
extension SubredditSearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.resultsController.startFetching(searchBar.text)
    }
    
}
