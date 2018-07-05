//
//  SubredditsSearchDataSource.swift
//  beam
//
//  Created by Robin Speijer on 10-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

let SubredditSearchCellIdentifier = "searched-subreddit"

protocol SubredditsSearchViewControllerDelegate: class {
    
    func searchViewController(_ viewController: SubredditsSearchViewController, didSelectSubreddit subreddit: Subreddit)
    
}

extension SubredditsSearchViewControllerDelegate {
    
    func searchViewController(_ viewController: SubredditsSearchViewController, didSelectSubreddit subreddit: Subreddit) {
        
    }
}

class SubredditsSearchViewController: BeamTableViewController, UISearchResultsUpdating, UISearchBarDelegate {

    weak var delegate: SubredditsSearchViewControllerDelegate?
    lazy var collectionController: CollectionController = {
        let query = SubredditsCollectionQuery()
        query.sortType = CollectionSortType.relevance
        query.hideNSFWSubreddits = !AppDelegate.shared.authenticationController.userCanViewNSFWContent
        
        let controller = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        controller.query = query
        return controller
    }()
    
    var objects: [Subreddit]?
    
    var localSearch = false {
        didSet {
            if localSearch == true {
                self.collectionController.query?.searchKeywords = nil
                self.collectionController.clear()
                self.typeTimer?.invalidate()
                self.typeTimer = nil
            }
            self.objects = nil
            self.tableView.reloadData()
            
            if localSearch {
                if let keywords = self.searchKeywords {
                    performLocalSearch(keywords)
                }
            } else {
                self.typeTimerFired()
            }
        }
    }
    
    var typeTimer: Timer?
    
    var searchKeywords: String? {
        didSet {
            if let searchKeywords = searchKeywords {
                if !self.localSearch {
                    self.typeTimer?.invalidate()
                    self.typeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(SubredditsSearchViewController.typeTimerFired), userInfo: nil, repeats: false)
                } else {
                    self.performLocalSearch(searchKeywords)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.registerForPreviewing(with: self, sourceView: self.tableView)
        
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let isLocal = (selectedScope == 0)
        if isLocal != self.localSearch {
            self.localSearch = isLocal
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let keywords = self.searchKeywords {
            if self.localSearch {
                self.performLocalSearch(keywords)
            } else if keywords.count > 1 {
                self.performRemoteSearch(keywords)
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if self.searchKeywords == nil {
            searchController.searchBar.delegate = self
            if self.localSearch != (searchController.searchBar.selectedScopeButtonIndex == 0) {
                self.localSearch = (searchController.searchBar.selectedScopeButtonIndex == 0)
            }
        }
        
        self.searchKeywords = searchController.searchBar.text
    }
    
    @objc fileprivate func typeTimerFired() {
        self.typeTimer = nil
        if let keywords = self.searchKeywords, keywords.count > 1 {
            self.performRemoteSearch(keywords)
        } else {
            self.collectionController.query?.searchKeywords = nil
            self.objects = nil
        }
    }
    
    fileprivate func performRemoteSearch(_ keywords: String) {
        self.collectionController.query?.searchKeywords = searchKeywords
        UIApplication.startNetworkActivityIndicator(for: self)
        self.collectionController.startInitialFetching(false) { [weak self] (newCollectionID, _) -> Void in
            self?.collectionController.managedObjectContext.perform {
                if self?.localSearch == false {
                    if let newCollectionID = newCollectionID, let newCollection = AppDelegate.shared.managedObjectContext.object(with: newCollectionID) as? ObjectCollection {
                        self?.objects = self?.filterSubreddits(newCollection.objects?.array as? [Subreddit])
                        self?.tableView.reloadData()
                    }
                }
                
                if let weakSelf = self {
                    UIApplication.stopNetworkActivityIndicator(for: weakSelf)
                }
            }
        }
    }
    
    fileprivate func performLocalSearch(_ keywords: String) {
        let fetchRequest = NSFetchRequest<Subreddit>(entityName: Subreddit.entityName())
        
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "title CONTAINS[cd] %@", keywords))
        predicates.append(NSPredicate(format: "isSubscriber = YES"))
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            let subreddits = try AppDelegate.shared.managedObjectContext.fetch(fetchRequest)
            self.objects = self.filterSubreddits(subreddits)
        } catch {
            NSLog("Error while searching local subreddits: \(error)")
        }
        
        self.tableView.reloadData()
    }
    
    func filterSubreddits(_ subreddits: [Subreddit]?) -> [Subreddit]? {
        guard let subredditsToFilter = subreddits else {
            return nil
        }
        if AppDelegate.shared.authenticationController.userCanViewNSFWContent {
            let filteredSubreddits: [Subreddit] = subredditsToFilter.filter({ (subreddit) -> Bool in
                return subreddit.isPrepopulated == false
            })
            return filteredSubreddits
        } else {
            let filteredSubreddits: [Subreddit] = subredditsToFilter.filter({ (subreddit) -> Bool in
                return subreddit.isNSFW?.boolValue == false && subreddit.isPrepopulated == false
            })
            return filteredSubreddits
        }
    }
    
    // UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.objects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell!
        if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: SubredditSearchCellIdentifier) {
            cell = dequeuedCell
        } else {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: SubredditSearchCellIdentifier)
        }
        
        let subreddit = self.objects?[indexPath.row]
        cell.textLabel?.text = subreddit?.displayName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = self.delegate, let subreddit = self.objects?[indexPath.row] {
            delegate.searchViewController(self, didSelectSubreddit: subreddit)
        }
    }
    
}

@available(iOS 9, *)
extension SubredditsSearchViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location), let cell = self.tableView.cellForRow(at: indexPath) else {
            return nil
        }
        guard let subreddit = self.objects?[indexPath.row] else {
            return nil
        }
        
        //Open the subreddit
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
            tabBarController.subreddit = subreddit
            
            //Set the frame to animate the peek from
            previewingContext.sourceRect = cell.frame
            
            //Pass the view controller to display
            return tabBarController
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        //We only show subreddit view controller in this view, which is always presented modally
        self.present(viewControllerToCommit, animated: true, completion: nil)
    }
}
