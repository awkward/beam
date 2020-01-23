//
//  SubredditTabBarController.swift
//  Beam
//
//  Created by Rens Verhoeven on 05-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import Trekker
import CoreData
import StoreKit

let ManageMultiredditSubsSegueIdentifier = "manageMultireddit"
let AddToMultiredditSegueIdentifier = "addtomultireddit"

class SubredditTabBarController: SmallTabBarController, UIAdaptivePresentationControllerDelegate {
    
    /// The subreddit to show
    var subreddit: Subreddit? {
        didSet {
            //Observe notifications if the subreddit is set
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: AppDelegate.shared.managedObjectContext)
            }
            if self.subreddit != nil {
                NotificationCenter.default.addObserver(self, selector: #selector(SubredditTabBarController.contextObjectsDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: AppDelegate.shared.managedObjectContext)
            }
            
            //If Stealthmode (aka private browsing) is enabled, don't mark anything on the subreddit!
            if let subreddit = subreddit, !UserSettings[.privacyModeEnabled] {
                //Make a user activity for search/siri indexing and handoff
                self.userActivity = subreddit.createUserActivity()
                
                //Mark the subreddit as visited
                let visitOperation = BlockOperation(block: { () -> Void in
                    subreddit.managedObjectContext?.performAndWait {
                        subreddit.lastVisitDate = Date()
                    }
                })
                DataController.shared.executeAndSaveOperations([visitOperation], context: AppDelegate.shared.managedObjectContext, handler: nil)
            }
            
            if self.subreddit != oldValue {
                //Make sure the view controllers have the newest subreddit
                self.configureSubViewControllers()
                
                //Update the title of the subreddit
                self.updateSubredditTitles()
            }
        }
    }
    
    /// If the media view is available. It's not available if the product is missing
    var mediaViewAvailable: Bool {
        return true
    }
    
    var streamViewController: SubredditStreamViewController? {
        let navigationController = self.viewControllers?.first as? UINavigationController
        return navigationController?.topViewController as? SubredditStreamViewController
    }
    
    // MARK: - Transition
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            return .fullScreen
        default:
            return .formSheet
        }
    }
    
    // MARK: - Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        presentationController?.delegate = self
        delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSubViewControllers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserSettings[.privacyModeEnabled] {
            self.userActivity?.becomeCurrent()
        }
        
        //People that do not update there iOS, are not the real users we want to target with app store reviews.
        if SKStoreReviewController.canRequestReview(with: self.subreddit) {
            UserSettings[.lastAppReviewRequestDate] = Date()
            SKStoreReviewController.requestReview()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !UserSettings[.privacyModeEnabled] {
            self.userActivity?.resignCurrent()
        }
    }
    
    // MARK: - User activity
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        if !UserSettings[.privacyModeEnabled] {
            activity.userInfo = self.subreddit?.userInfoForUserActivity()
        }
    }
    
    // MARK: - View Controllers
    
    fileprivate func configureSubViewControllers() {
        guard let viewControllers = self.viewControllers, viewControllers.count > 0 else {
            return
        }
        
        //Update the subreddit on the view controllers
        for viewController in viewControllers {
            if let navigationController = viewController as? BeamNavigationController,
                var subredditTabItemViewController = navigationController.topViewController as? SubredditTabItemViewController, subredditTabItemViewController.subreddit?.identifier != self.subreddit?.identifier {
                subredditTabItemViewController.subreddit = self.subreddit
            }
        }
        
        if let navigationController = self.selectedViewController as? UINavigationController, navigationController.topViewController is SubredditMediaOverviewViewController {
            //Do not continue with updating the media view!
            return
        }
        
        var shouldSelectMediaView = false
        
        // The index of where the media view will be in the tabbar
        let mediaViewIndex = 1
        
        // Filter the view controllers to find the view controllers related to the media view controller
        let mediaNavigationControllers: [UINavigationController] = viewControllers.filter({ (viewController: UIViewController) -> Bool in
            if let navigationController = viewController as? UINavigationController, let topViewController = navigationController.topViewController {
                return topViewController is SubredditMediaOverviewViewController
            }
            return false
        }) as! [UINavigationController]
        
        //Check if a the media view is already in the tabbar
        let mediaViewController = mediaNavigationControllers.first(where: {
            let navigationController: UINavigationController = $0
            guard let topViewController = navigationController.topViewController else {
                return false
            }
            return topViewController is SubredditMediaOverviewViewController
        })?.topViewController as? SubredditMediaOverviewViewController
        
        //Only configure the media view controller if it's not already in there
        if mediaViewController == nil {
            // Remove the media view controllers
            for mediaView in mediaNavigationControllers {
                if let index = viewControllers.firstIndex(of: mediaView) {
                    self.viewControllers?.remove(at: index)
                    shouldSelectMediaView = self.selectedIndex == mediaViewIndex
                }
            }
            
            // Then add back media view, if appropiate
            if self.mediaViewAvailable {
                let storyboard = UIStoryboard(name: "MediaOverview", bundle: Bundle.main)
                
                let tabBarItem = UITabBarItem(title: NSLocalizedString("media", comment: "Media tabbar item"), image: UIImage(named: "tabbar_mediaview"), selectedImage: nil)
                
                if let viewController = storyboard.instantiateInitialViewController() {
                    //Make sure the new viewController has a subreddit
                    if var tabBarItemViewController = viewController as? SubredditTabItemViewController {
                        tabBarItemViewController.subreddit = self.subreddit
                    }
                    
                    let navigationController = BeamNavigationController()
                    navigationController.setViewControllers([viewController], animated: false)
                    navigationController.tabBarItem = tabBarItem
                    self.viewControllers?.insert(navigationController, at: mediaViewIndex)
                    if shouldSelectMediaView {
                        self.selectedIndex = mediaViewIndex
                    }
                }
            }
        }
        
        self.applyGestureRecognizersToSelectedViewController()
    }
    
    // MARK: - Dismissal
    
    private lazy var dismissalGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let gr = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(SubredditTabBarController.dismiss))
        gr.edges = .left
        gr.maximumNumberOfTouches = 1
        return gr
    }()
    
    fileprivate func applyGestureRecognizersToSelectedViewController() {
        if let view = selectedViewController?.view {
            view.addGestureRecognizer(dismissalGestureRecognizer)
        } else {
            dismissalGestureRecognizer.view?.removeGestureRecognizer(dismissalGestureRecognizer)
        }
    }
    
    @objc private func panScreenEdgeDismissal(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard presentingViewController != nil && gestureRecognizer.state == .recognized else { return }
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Subreddit updates
    
    fileprivate func updateSubredditTitles() {
        
        //Update the title of the view for accessability
        self.title = self.subreddit?.displayName
        
        guard let viewControllers = self.viewControllers, viewControllers.count > 0 else {
            return
        }
        
        //Update the subreddit on the view controllers
        for viewController in viewControllers {
            if let navigationController = viewController as? UINavigationController,
                let subredditTabItemViewController = navigationController.topViewController as? SubredditTabItemViewController,
                subredditTabItemViewController.subreddit?.identifier != self.subreddit?.identifier {
                subredditTabItemViewController.updateNavigationItem()
            }
        }
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func contextObjectsDidChange(_ notification: Notification?) {
        DispatchQueue.main.async { () -> Void in
            if let subreddit = self.subreddit {
                let updatedObjects = (notification as NSNotification?)?.userInfo?[NSUpdatedObjectsKey] as? NSSet
                if updatedObjects?.contains(subreddit) == true {
                    self.updateSubredditTitles()
                }
                
                // Dismiss subreddit if it is deleted
                let deletedObjects = (notification as NSNotification?)?.userInfo?[NSDeletedObjectsKey] as? NSSet
                if deletedObjects?.contains(subreddit) == true {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - General actions
    
    @objc func closeTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func composeTapped(_ sender: UIBarButtonItem) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.CreatePost), animated: true, completion: nil)
            return
        }
        let alertController = BeamAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        if self.subreddit?.submissionType.canPostSelfText == true {
            alertController.addAction(UIAlertAction(title: AWKLocalizedString("create-text-post-button"), style: UIAlertAction.Style.default, handler: { (_) in
                self.showCreatePost("create-text-post")
            }))
        }
        if self.subreddit?.submissionType.canPostLink == true {
            alertController.addAction(UIAlertAction(title: AWKLocalizedString("create-link-post-button"), style: UIAlertAction.Style.default, handler: { (_) in
                self.showCreatePost("create-link-post")
            }))
            alertController.addAction(UIAlertAction(title: AWKLocalizedString("create-image-post-button"), style: UIAlertAction.Style.default, handler: { (_) in
                self.showCreatePost("create-image-post")
            }))
        }
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.addCancelAction()
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    @objc func copyMultireddit(_ sender: Any) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.Subscribe), animated: true, completion: nil)
            return
        }
        Trekker.default.track(event: TrekkerEvent(event: "Copy Multireddit", properties: ["View": "Navigation Bar"]))
        self.showCopyMultireddit()
    }
    
    // MARK: - Create Post
    
    fileprivate func showCreatePost(_ identifier: String) {
        let storyBoard = UIStoryboard(name: "CreatePost", bundle: nil)
        if let navigationController = storyBoard.instantiateViewController(withIdentifier: identifier) as? UINavigationController, let createPostViewController = navigationController.topViewController as? CreatePostViewController {
            createPostViewController.subreddit = self.subreddit
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Multireddit actions
    
    func showManageSubreddits() {
        if let multireddit = self.subreddit as? Multireddit, multireddit.canEdit?.boolValue == true {
            self.performSegue(withIdentifier: ManageMultiredditSubsSegueIdentifier, sender: nil)
        }
    }
    
    func showAddToMultireddit() {
        if let subreddit = self.subreddit, !(subreddit is Multireddit) {
            self.performSegue(withIdentifier: AddToMultiredditSegueIdentifier, sender: nil)
        }
    }
    
    func showEditMultireddit() {
        let storyboard = UIStoryboard(name: "EditMultireddit", bundle: nil)
        if let multireddit = self.subreddit as? Multireddit, let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController, let editMultiredditViewController = navigationController.viewControllers.first as? EditMultiredditViewController, multireddit.canEdit?.boolValue == true {
            editMultiredditViewController.multireddit = multireddit
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    fileprivate func showCopyMultireddit() {
        let storyboard = UIStoryboard(name: "EditMultireddit", bundle: nil)
        if let multireddit = self.subreddit as? Multireddit, let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController, let editMultiredditViewController = navigationController.viewControllers.first as? EditMultiredditViewController {
            editMultiredditViewController.copyingMultireddit = true
            editMultiredditViewController.multireddit = multireddit
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Requests
    
    func cancelAllRequests() {
        guard let viewControllers = self.viewControllers, viewControllers.count > 0 else {
            return
        }
        
        if let subredditStreamViewController = viewControllers[0] as? SubredditStreamViewController, let streamViewController = subredditStreamViewController.streamViewController {
            streamViewController.cancelRequests()
        } else {
            AWKDebugLog("Couldn't find a StreamViewController at index 0")
        }
        
        if let subredditMediaViewController = viewControllers[1] as? SubredditMediaOverviewViewController {
            subredditMediaViewController.cancelRequests()
        } else {
            AWKDebugLog("Couldn't find a SubredditMediaOverViewController at index 1")
        }
    }

    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ManageMultiredditSubsSegueIdentifier {
            if let navigation = segue.destination as? UINavigationController, let viewController = navigation.topViewController as? MultiredditSubsViewController, let multireddit = self.subreddit as? Multireddit {
                viewController.multireddit = multireddit
            }
        } else if segue.identifier == AddToMultiredditSegueIdentifier {
            if let navigation = segue.destination as? UINavigationController, let viewController = navigation.topViewController as? AddToMultiredditViewController, let subreddit = self.subreddit {
                viewController.subreddit = subreddit
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == ManageMultiredditSubsSegueIdentifier && !(self.subreddit is Multireddit) {
            return false
        }
        return true
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.dismiss(animated: true, completion: nil)
        return true
    }

}

extension SubredditTabBarController {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.applyGestureRecognizersToSelectedViewController()
    }
    
}
