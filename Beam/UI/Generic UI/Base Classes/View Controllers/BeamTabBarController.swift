//
//  BeamTabBarController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

protocol TabBarItemLongPressActionable {
    
    func tabBarItemDidRecognizeLongPress(_ tabBarItem: UITabBarItem)
    
}

class BeamTabBarController: UITabBarController, DynamicDisplayModeView {
    
    lazy private var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(gestureRecognizer:)))
        return gestureRecognizer
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.delegate = self
        
        registerForDisplayModeChangeNotifications()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.delegate = self
        
        registerForDisplayModeChangeNotifications()
    }
    
    deinit {
        unregisterForDisplayModeChangeNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.addGestureRecognizer(self.longPressGestureRecognizer)
    }
    
    func displayModeDidChange() {
        switch displayMode {
        case .dark:
            tabBar.barTintColor = UIColor.beamDarkContentBackgroundColor()
            tabBar.tintColor = UIColor.beamPurpleLight()
        case .default:
            tabBar.barTintColor = UIColor.beamBarColor()
            tabBar.tintColor = UIColor.beamColor()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            return .all
        }
        return .portrait
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.selectedViewController?.preferredStatusBarStyle ?? (self.displayMode == .dark ? UIStatusBarStyle.lightContent: UIStatusBarStyle.default)
    }
    
    override var shouldAutorotate: Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    // MARK: - Notifications
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        self.displayModeDidChangeAnimated(true)
    }
    
    // MARK: - Actions
    
    @objc private func handleLongPressGesture(gestureRecognizer: UILongPressGestureRecognizer) {
        guard let selectedViewController = self.selectedViewController else {
            return
        }
        var actionable: TabBarItemLongPressActionable? = selectedViewController as? TabBarItemLongPressActionable
        if let navigationController = selectedViewController as? UINavigationController {
            actionable = navigationController.viewControllers.first as? TabBarItemLongPressActionable
        }
        
        if gestureRecognizer.state == .began, let actionable = actionable {
            actionable.tabBarItemDidRecognizeLongPress(selectedViewController.tabBarItem)
        }
    }
    
}

extension BeamTabBarController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if tabBarController.selectedViewController == viewController {
            //The viewcontroller is already selected, so the tabbar items was tapped again, now scroll the first UIScrollView to the top
            self.scrollViewControllerToTop(viewController)
        }
        return true
    }
    
    /**
     If you have to use a custom delegate for the BeamTabBarController you can call this method yourself if the `viewController` in `tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController)` is the same as the selectedViewController. By default the tabBarControllerDelegate is set to BeamTabBarController.
     */
    func scrollViewControllerToTop(_ viewController: UIViewController) {
        var scrollViewViewController = viewController
        //If the scrollViewController is a UINavigationController, we need to get the topViewController because that is actually where the scrollview will be
        if let navigationController = scrollViewViewController as? UINavigationController, let topViewController = navigationController.topViewController {
            scrollViewViewController = topViewController
        }
        //Check for a UIScrollView only in the first 2 layers of the view hierachy and check if the scrollview is visible and supports scroll to top
        if let scrollView = self.findVisibleScrollView(scrollViewViewController.view) {
            if scrollView.delegate?.scrollViewShouldScrollToTop?(scrollView) ?? true {
                //scrollView.contentOffset will not stop the scrollview from scrolling if it's already scrolling before doing the animation.
                scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 20, height: 20), animated: true)
                scrollView.delegate?.scrollViewDidScrollToTop?(scrollView)
            }
            
        }
    }
    
    //Find a view based on UIScrollView, but only 2 levels deep.
    fileprivate func findVisibleScrollView(_ view: UIView) -> UIScrollView? {
        
        func isValidScrollView(_ scrollView: UIScrollView) -> Bool {
            return (scrollView.isHidden == false && scrollView.window != nil && scrollView.superview?.isHidden == false)
        }
        
        var validScrollView: UIScrollView?
        if let scrollView = view as? UIScrollView, isValidScrollView(scrollView) {
            validScrollView = scrollView
        }
        if validScrollView == nil {
            for subview in view.subviews {
                if let scrollView = subview as? UIScrollView, isValidScrollView(scrollView) {
                    validScrollView = scrollView
                    break
                }
            }
        }
        if validScrollView == nil {
            for firstSubview in view.subviews {
                for subview in firstSubview.subviews {
                    if let scrollView = subview as? UIScrollView, isValidScrollView(scrollView) {
                        validScrollView = scrollView
                        break
                    }
                    //We found a scrollview, break out of the second loop
                    if validScrollView != nil {
                        break
                    }
                }
            }
        }
        return validScrollView
    }
}
