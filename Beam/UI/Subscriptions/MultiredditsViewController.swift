//
//  MyMultiredditsViewController.swift
//  beam
//
//  Created by Robin Speijer on 06-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData
import CherryKit

private let reuseIdentifier = "multireddit"

final class MultiredditsViewController: BeamTableViewController, NSFetchedResultsControllerDelegate, BeamViewControllerLoading {
    
    typealias CollectionItem = Multireddit
    
    // MARK: - Properties
    
    lazy var collectionController: CollectionController = {
        let controller = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        
        let query = MultiredditCollectionQuery()
        controller.query = query
        controller.delegate = self
        
        return controller
    }()
    
    var loadingState: BeamViewControllerLoadingState = .empty
    var emptyView: BeamEmptyView? {
        didSet {
            self.tableView.backgroundView = self.emptyView
            self.emptyView?.layoutMargins = self.tableView.contentInset
        }
    }
    var defaultEmptyViewType = BeamEmptyViewType.SubredditsNoMultireddits
    
    func emptyViewTypeForState(_ state: BeamViewControllerLoadingState) -> BeamEmptyViewType {
        switch state {
        case .loading:
            return BeamEmptyViewType.Loading
        case .noInternetConnection:
            return BeamEmptyViewType.Error
        case .noAccess:
            return BeamEmptyViewType.MultiredditsNotLoggedIn
        default:
            return self.defaultEmptyViewType
        }
    }
    
    var content: [Multireddit]? {
        didSet {
            self.tableView.reloadData()
        }
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(SubredditTableViewCell.self)
        
        self.title = "My Multireddits"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(MultiredditsViewController.createMultireddit(_:)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(MultiredditsViewController.authenticatedUserDidChange(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MultiredditsViewController.expiredContentDeleted(_:)), name: .DataControllerExpiredContentDeletedFromContext, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MultiredditsViewController.multiredditDidUpdate(_:)), name: MultiredditDidUpdateNotificationName, object: nil)
        
        self.registerForPreviewing(with: self, sourceView: self.tableView)
        
        //Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshContent(sender:)), for: .valueChanged)
        self.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.startCollectionControllerFetching(respectingExpirationDate: true)
        
    }
    
    func unwindFromSubredditToMyMultireddits(_ segue: UIStoryboardSegue) {
        
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.emptyView?.layoutMargins = self.tableView.contentInset
    }
    
    // MARK: - Data
    
    @objc func authenticatedUserDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            if AppDelegate.shared.authenticationController.isAuthenticated {
                self.title = AWKLocalizedString("my-multireddits-title")
            } else {
                self.title = AWKLocalizedString("multireddits-title")
            }
            
            self.content = nil
            self.startCollectionControllerFetching(respectingExpirationDate: false)
        }
        
    }
    
    @objc fileprivate func expiredContentDeleted(_ notification: Notification) {
        if let managedObjectContext = notification.object as? NSManagedObjectContext, managedObjectContext.deletedObjects.contains( where: { $0 is Multireddit }) {
            DispatchQueue.main.async { () -> Void in
                self.startCollectionControllerFetching(respectingExpirationDate: false)
            }
        }
    }
    
    @objc fileprivate func multiredditDidUpdate(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.startCollectionControllerFetching(respectingExpirationDate: false)
        }
    }
    
    // MARK: - Actions
    
    @objc fileprivate func refreshContent(sender: UIRefreshControl) {
        self.startCollectionControllerFetching(respectingExpirationDate: false)
    }
    
    @objc fileprivate func createMultireddit(_ sender: AnyObject) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.CreateMultireddit), animated: true, completion: nil)
            return
        }
        
        let storyboard = UIStoryboard(name: "EditMultireddit", bundle: nil)
        if let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController {
            self.present(navigationController, animated: true, completion: nil)
        }
    }
}

// MARK: - UITableViewDataSource

extension MultiredditsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.content?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let multireddit = self.content![indexPath.row]
        
        let cell: SubredditTableViewCell = tableView.dequeueReusable(for: indexPath)
        cell.subreddit = multireddit
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62.5
    }
    
}

// MARK: - UITableViewDelegate

extension MultiredditsViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let multireddit = self.content?[indexPath.row] else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
            tabBarController.subreddit = multireddit
            self.present(tabBarController, animated: true, completion: nil)
        }
    }
    
}

// MARK: - CollectionControllerDelegate
extension MultiredditsViewController: CollectionControllerDelegate {
    
    func collectionController(_ controller: CollectionController, collectionDidUpdateWithID objectID: NSManagedObjectID?) {
        DispatchQueue.main.async { () -> Void in
            self.refreshControl?.endRefreshing()
            self.updateContent()
        }
    }
    
    func collectionControllerShouldFetchMore(_ controller: CollectionController) -> Bool {
        return true
    }
    
    func collectionController(_ controller: CollectionController, didUpdateStatus newStatus: CollectionControllerStatus) {
        
    }
    
}

@available(iOS 9, *)
extension MultiredditsViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location), let cell = self.tableView.cellForRow(at: indexPath) else {
            return nil
        }
        guard let multireddit = self.content?[indexPath.row] else {
            return nil
        }
        
        //Open the subreddit
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
            tabBarController.subreddit = multireddit
            
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
