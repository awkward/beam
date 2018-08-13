//
//  CurrentUserProfileViewController.swift
//  beam
//
//  Created by Rens Verhoeven on 14-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

class CurrentUserProfileViewController: ProfileViewController {
    
    lazy var loginEmptyState: BeamEmptyView = {
        let view = BeamEmptyView.emptyView(.ProfileNotLoggedIn, frame: self.view.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[emptyState]|", options: [], metrics: nil, views: ["emptyState": view]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[emptyState]|", options: [], metrics: nil, views: ["emptyState": view]))
        return view
    }()
    
    lazy var profileTitleButton: ProfileSwitchButton = {
        var button = ProfileSwitchButton()
        button.addTarget(self, action: #selector(CurrentUserProfileViewController.tappedProfileTitle(_:)), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    override var user: User? {
        didSet {
            DispatchQueue.main.async { () -> Void in
                if self.user != oldValue {
                    self.configureLoginView()
                }
            }
            
        }
    }
    
    func configureLoginView() {
        let loginHidden = AppDelegate.shared.authenticationController.isAuthenticated
        self.loginEmptyState.isHidden = loginHidden
        //Content inset is not usable in the current profile view, use your own constraints
        
        self.loginEmptyState.layoutMargins = UIEdgeInsets(top: self.topLayoutGuide.length + 44, left: 0, bottom: self.bottomLayoutGuide.length, right: 0)
        self.toolbar.isHidden = !loginHidden
        self.headerView.isHidden = !loginHidden
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        self.sections.append(ProfileContentSection(type: .upvoted, stream: self.streamViewControllerWithContentType(.upvoted)))
        self.sections.append(ProfileContentSection(type: .saved, stream: self.streamViewControllerWithContentType(.saved)))
        self.sections.append(ProfileContentSection(type: .hidden, stream: self.streamViewControllerWithContentType(.hidden)))
        
        super.viewDidLoad()
        
        self.user = nil
        self.configureLoginView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CurrentUserProfileViewController.postDidChangeSavedState(_:)), name: .ContentDidChangeSavedState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CurrentUserProfileViewController.postDidChangeHiddenState(_:)), name: .PostDidChangeHiddenState, object: nil)

        self.userDidChange(nil)
    }
    
    override func updateTitle() {
        let accounts = AppDelegate.shared.authenticationController.fetchAllAuthenticationSessions()
        let username = self.username ?? AWKLocalizedString("profile-title")
        self.title = username
        self.profileTitleButton.title = username
        self.profileTitleButton.showArrow = accounts.count > 1
        self.profileTitleButton.sizeToFit()
        self.navigationItem.titleView = nil
        self.navigationItem.titleView = self.profileTitleButton
        self.navigationController?.tabBarItem.title = AWKLocalizedString("profile-title")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Authentication
    
    override func userDidChange(_ notification: Notification?) {
        DispatchQueue.main.async { () -> Void in
            super.userDidChange(notification)
            self.user = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)
        }
    }
    
    @objc fileprivate func postDidChangeSavedState(_ notification: Notification?) {
        DispatchQueue.main.async { () -> Void in
            //Refresh the posts in the saved view controller
            if let streamViewController = self.sections.first(where: { $0.type == UserContentType.saved })?.stream {
                streamViewController.startCollectionControllerFetching(respectingExpirationDate: false, overwrite: true)
            }
        }
    }
    
    @objc fileprivate func postDidChangeHiddenState(_ notification: Notification?) {
        DispatchQueue.main.async { () -> Void in
            //Refresh the posts in the saved view controller
            if let streamViewController = self.sections.first(where: { $0.type == UserContentType.saved })?.stream {
                streamViewController.startCollectionControllerFetching(respectingExpirationDate: false, overwrite: true)
            }
        }
    }

    // MARK: - Actions
    
    @IBAction func profileButtonTapped(_ sender: AnyObject) {
        let upgradeStoryboard = UIStoryboard(name: "Settings", bundle: nil)
        if let viewController = upgradeStoryboard.instantiateInitialViewController() {
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func tappedProfileTitle(_ sender: ProfileSwitchButton) {
        AppDelegate.shared.presentAccountSwitcher(sender: sender)
    }
    
    @IBAction func unwindFromSettingsToProfile(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func unwindToProfile(_ segue: UIStoryboardSegue) {
        
    }
    
}

extension CurrentUserProfileViewController: TabBarItemLongPressActionable {

    func tabBarItemDidRecognizeLongPress(_ tabBarItem: UITabBarItem) {
        guard let tabBar = self.tabBarController?.tabBar else {
            return
        }
        AppDelegate.shared.presentAccountSwitcher(sender: tabBar)
    }
}
