//
//  AddToMultiredditViewController.swift
//  beam
//
//  Created by Robin Speijer on 13-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData
import Snoo

let AddToMultiredditCellReuseIdentifier = "multireddit"

class AddToMultiredditViewController: BeamTableViewController, BeamViewControllerLoading {
    
    typealias CollectionItem = Multireddit
    
    var subreddit: Subreddit? //Must be on the main context!
    
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
        
        assert(self.subreddit?.managedObjectContext == AppDelegate.shared.managedObjectContext)
        
        self.title = AWKLocalizedString("add-to-multireddit")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(UIViewController.dismissViewController(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(AddToMultiredditViewController.createMultireddit(_:)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(AddToMultiredditViewController.authenticatedUserDidChange(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AddToMultiredditViewController.expiredContentDeleted(_:)), name: .DataControllerExpiredContentDeletedFromContext, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AddToMultiredditViewController.multiredditDidUpdate(_:)), name: MultiredditDidUpdateNotificationName, object: nil)
        
        self.registerForPreviewing(with: self, sourceView: self.tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.startCollectionControllerFetching(respectingExpirationDate: true)
        
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.emptyView?.layoutMargins = self.tableView.contentInset
    }
    
    // MARK: - Data
    
    @objc func authenticatedUserDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
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
    
    @objc func createMultireddit(_ sender: AnyObject) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.CreateMultireddit), animated: true, completion: nil)
            return
        }
        
        let storyboard = UIStoryboard(name: "EditMultireddit", bundle: nil)
        if let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController {
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    // MARK: Layout
}

// MARK: - UITableViewDataSource

extension AddToMultiredditViewController {
    
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
        cell.allowPromimentDisplay = false
        cell.subreddit = multireddit
       
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension AddToMultiredditViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let multireddit = self.content?[indexPath.row], let subreddit = self.subreddit, let originalSubreddits = multireddit.subreddits, let context = multireddit.managedObjectContext {
            
            multireddit.subreddits = originalSubreddits.adding(subreddit) as NSSet
            
            let authenticationController = AppDelegate.shared.authenticationController
            let request = multireddit.updateOperation(authenticationController)
            
            DataController.shared.executeAndSaveOperations([request], context: context, handler: { [weak self] (error: Error?) -> Void in
                if let error = error {
                    DispatchQueue.main.sync {
                        let alert = BeamAlertController(title: "Could not update multireddit", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self?.present(alert, animated: true, completion: nil)
                        
                        multireddit.subreddits = originalSubreddits
                        
                    }
                } else {
                    self?.navigationController?.dismiss(animated: true, completion: nil)
                }
                
                if let weakSelf = self {
                    UIApplication.stopNetworkActivityIndicator(for: weakSelf)
                }
            })
            
        }
    }
    
}

// MARK: - CollectionControllerDelegate
extension AddToMultiredditViewController: CollectionControllerDelegate {
    
    func collectionController(_ controller: CollectionController, collectionDidUpdateWithID objectID: NSManagedObjectID?) {
        DispatchQueue.main.async { () -> Void in
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
extension AddToMultiredditViewController: UIViewControllerPreviewingDelegate {
    
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
