//
//  SubredditListViewController.swift
//  beam
//
//  Created by Robin Speijer on 15-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData
import Snoo

class SubredditListViewController: BeamTableViewController, BeamViewControllerLoading {

    typealias CollectionItem = Subreddit
    
    lazy var collectionController: CollectionController = {
        let controller = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        return controller
    }()
    
    var loadingState: BeamViewControllerLoadingState = .empty
    var emptyView: BeamEmptyView? {
        didSet {
            self.tableView.backgroundView = self.emptyView
        }
    }
    var defaultEmptyViewType: BeamEmptyViewType = BeamEmptyViewType.SearchNoResults
    
    var content: [Subreddit]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var subredditQuery: SubredditsCollectionQuery? {
        didSet {
            if !AppDelegate.shared.authenticationController.userCanViewNSFWContent {
                subredditQuery?.contentPredicate = NSPredicate(format: "isNSFW != YES")
            }
            self.collectionController.query = self.subredditQuery
            self.startCollectionControllerFetching(respectingExpirationDate: false, overwrite: true)
        }
    }
    
    lazy var subscribersCountNumberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        return numberFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.registerForPreviewing(with: self, sourceView: self.tableView)
    }

}

// MARK: - UITableViewDataSource
extension SubredditListViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.content?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 13
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SubredditListTableViewCell
        let subreddit = self.content?[indexPath.row]
        
        cell.subreddit = subreddit
        
        return cell
    }
    
}

extension SubredditListViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let subreddit = self.content?[indexPath.row] {
            
            if subreddit.isUserAuthorized {
                //Open the subreddit
                let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
                if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
                    tabBarController.subreddit = subreddit
                    self.present(tabBarController, animated: true, completion: nil)
                }
            } else {
                let alert = BeamAlertController(title: AWKLocalizedString("search_subreddit_private"), message: subreddit.publicDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addCancelAction({ (_) in
                    tableView.deselectRow(at: indexPath, animated: true)
                })
                if !AppDelegate.shared.authenticationController.isAuthenticated {
                    alert.addAction(UIAlertAction(title: AWKLocalizedString("login"), style: .default, handler: { (_) -> Void in
                        tableView.deselectRow(at: indexPath, animated: false)
                        AppDelegate.shared.changeActiveTabContent(AppTabContent.ProfileNavigation)
                        
                    }))
                }
                self.present(alert, animated: true, completion: nil)
            }
            
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
}

@available(iOS 9, *)
extension SubredditListViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //Cell selection
        guard let indexPath = self.tableView.indexPathForRow(at: location), let cell = self.tableView.cellForRow(at: indexPath) else {
            return nil
        }
        guard let subreddit = self.content?[indexPath.row] else {
            return nil
        }
        
        //Make the subreddit previewing view controller
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
