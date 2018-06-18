//
//  SubredditsViewController.swift
//  beam
//
//  Created by Robin Speijer on 01-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

final class HomeViewController: BeamViewController, UIToolbarDelegate {
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var topButtonBarConstraint: NSLayoutConstraint!
    
    var touchForwardingView: TouchesForwardingView?
    
    var buttonBarItem: UIBarButtonItem {
        return toolbar.items![1]
    }
    
    @IBOutlet weak var buttonBar: ButtonBar!
    
    lazy private var subredditsViewController: SubredditsViewController = {
        return SubredditsViewController(style: .plain)
    }()
    
    lazy private var multiredditsViewController: MultiredditsViewController = {
        return MultiredditsViewController(style: .grouped)
    }()
    
    var currentViewController: UIViewController! {
        didSet {
            if oldValue != currentViewController {
                
                self.touchForwardingView?.receivingView = self.currentViewController.view
                
                self.navigationController?.navigationBar.setItems([currentViewController.navigationItem], animated: false)
                self.subredditsViewController.view.isHidden = currentViewController != self.subredditsViewController
                self.multiredditsViewController.view.isHidden = currentViewController != self.multiredditsViewController
                
                if currentViewController == self.subredditsViewController {
                    self.buttonBar.selectedItemIndex = 0
                } else {
                    self.buttonBar.selectedItemIndex = 1
                }
            }
        }
    }
    
    // MARK: - UIViewController
    
    private func setupView() {
        self.view.insertSubview(self.multiredditsViewController.view, belowSubview: self.toolbar)
        self.addChildViewController(self.multiredditsViewController)
        self.multiredditsViewController.didMove(toParentViewController: self)
        
        self.addContainerViewConstraints(viewController: self.multiredditsViewController, containerView: self.view)
        
        self.view.insertSubview(self.subredditsViewController.view, belowSubview: self.toolbar)
        self.addChildViewController(self.subredditsViewController)
        self.subredditsViewController.didMove(toParentViewController: self)
        
        self.addContainerViewConstraints(viewController: self.subredditsViewController, containerView: self.view)
        
        if self.touchForwardingView == nil {
            self.touchForwardingView = self.multiredditsViewController.tableView.expandScrollArea()
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        
        self.buttonBar.items = [ButtonBarButton(title: AWKLocalizedString("subreddits-title")), ButtonBarButton(title: AWKLocalizedString("multireddits-title"))]
        self.buttonBar.addTarget(self, action: #selector(HomeViewController.buttonBarChanged(_:)), for: UIControlEvents.valueChanged)
        self.buttonBar.selectedItemIndex = UserSettings[.subscriptionsListType] == "multireddits" ? 1: 0
        
        self.configureContentInsets()
        
    }
    
    fileprivate func addContainerViewConstraints(viewController: UIViewController, containerView: UIView) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            viewController.view.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor),
            containerView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            containerView.rightAnchor.constraint(greaterThanOrEqualTo: viewController.view.rightAnchor),
            
            //Add horizontal constraints to make the view center with a max width
            viewController.view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            viewController.view.widthAnchor.constraint(lessThanOrEqualToConstant: UIView.MaximumViewportWidth)
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        //Limit the actual width, but give it a lower priority (750) so that it can be smaller if it needs to be (on iPhone for example)
        let widthConstraint = NSLayoutConstraint(item: viewController.view, attribute: .width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: UIView.MaximumViewportWidth)
        widthConstraint.priority = UILayoutPriority.defaultHigh
        viewController.view.addConstraint(widthConstraint)
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[viewController]|", options: [], metrics: nil, views: ["viewController": viewController.view]))
        
        //Disable the scrollbar on iPad, it looks weird
        if let tableView = viewController.view as? UITableView, UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            tableView.showsVerticalScrollIndicator = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.currentViewController = self.buttonBar.selectedItemIndex == 1 ? self.multiredditsViewController: self.subredditsViewController
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.buttonBarItem.width = self.toolbar.bounds.width
        configureContentInsets()
    }
    
    func configureContentInsets() {
        let contentInsets = UIEdgeInsets(top: self.toolbar.bounds.height, left: 0, bottom: 0, right: 0)
        
        self.subredditsViewController.tableView.contentInset = contentInsets
        self.subredditsViewController.tableView.scrollIndicatorInsets = contentInsets
        if self.subredditsViewController.tableView.contentOffset.y <= 0 {
            self.subredditsViewController.tableView.contentOffset = CGPoint(x: 0, y: -1 * contentInsets.top)
        }
        
        self.multiredditsViewController.tableView.contentInset = contentInsets
        self.multiredditsViewController.tableView.scrollIndicatorInsets = contentInsets
        if self.multiredditsViewController.tableView.contentOffset.y <= 0 {
            self.multiredditsViewController.tableView.contentOffset = CGPoint(x: 0, y: -1 * contentInsets.top)
        }
    }
    
    // MARK: - UIBarPositioningDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.top
    }
    
    // MARK: - Actions
    
    @objc fileprivate func buttonBarChanged(_ sender: ButtonBar) {
        if sender.selectedItemIndex == 1 {
            self.currentViewController = self.multiredditsViewController
        } else {
            self.currentViewController = self.subredditsViewController
        }
    }

}

extension HomeViewController: NavigationBarNotificationDisplayingDelegate {

    func topViewForDisplayOfnotificationView<NotificationView: UIView>(_ view: NotificationView) -> UIView? where NotificationView: NavigationBarNotification {
        return self.buttonBar.superview
    }
    
}
