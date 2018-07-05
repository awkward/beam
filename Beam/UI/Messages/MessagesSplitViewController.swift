//
//  MessagesSplitViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 30/11/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

extension UISplitViewController {
    
    /// Toggleing the master view as an overlay is possible in code, but requires you to manage the complete display mode state etc.
    /// This is a simple hack using the supplied button to toggle the overlay view, with the default animation.
    /// It simply perform the same action as the default display mode button item you are suppose to add to a UINavigationItem of the secondaryViewController
    /// http://stackoverflow.com/questions/27243158/hiding-the-master-view-controller-with-uisplitviewcontroller-in-ios8
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem
        guard let action = self.displayModeButtonItem.action else {
            return
        }
        
        UIApplication.shared.sendAction(action, to: barButtonItem.target, from: nil, for: nil)
    }
}

class MessagesSplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setting the delegate before presentWithGesture is set.
        self.presentsWithGesture = true
        //Setting the delegate after the viewDidLoad of the UISplitViewController will cause the gesture to stop working, that's why this is a subclass the handles the UISplitViewControllerDelegate
        self.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.viewControllers.count > 1 {
            if let navigationController = self.viewControllers[1] as? UINavigationController, navigationController.topViewController is NoMessageSelectedViewController && self.displayMode != .allVisible {
                self.preferredDisplayMode = .primaryOverlay
                self.preferredDisplayMode = .automatic
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

}

//Setting the delegate after the viewDidLoad of the UISplitViewController will cause the gesture to stop working, that's why this is a subclass the handles the UISplitViewControllerDelegate
extension MessagesSplitViewController: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool {
        //Handle the default behavior
        return false
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        if splitViewController.isCollapsed {
            guard let navigationController = splitViewController.viewControllers.first as? UINavigationController else {
                return false
            }
            navigationController.pushViewController(vc, animated: true)
        } else {
            if let navigationController = splitViewController.viewControllers[1] as? BeamColorizedNavigationController {
                navigationController.setViewControllers([vc], animated: false)
            } else {
                let navigationController = BeamColorizedNavigationController(rootViewController: vc)
                navigationController.useInteractiveDismissal = false
                splitViewController.viewControllers = [splitViewController.viewControllers.first!, navigationController]
            }
            
        }
        //We did override this behavior!
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let primaryNavigationController = primaryViewController as? UINavigationController, let secondaryNavigationController = secondaryViewController as? UINavigationController else {
            return false
        }
        if let messageViewController = secondaryNavigationController.viewControllers.first as? MessageConversationViewController {
            primaryNavigationController.pushViewController(messageViewController, animated: true)
        }
        secondaryNavigationController.viewControllers = []
        
        return false
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        guard let primaryNavigationController = primaryViewController as? UINavigationController else {
            return nil
        }
        
        let navigationController = BeamColorizedNavigationController()
        navigationController.useInteractiveDismissal = false
        if primaryNavigationController.viewControllers.last is MessageConversationViewController {
            let viewController = primaryNavigationController.popViewController(animated: true)!
            navigationController.viewControllers = [viewController]
        }
        
        return navigationController
    }
    
    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewControllerDisplayMode {
        return UISplitViewControllerDisplayMode.automatic
    }
    
    func splitViewControllerSupportedInterfaceOrientations(_ splitViewController: UISplitViewController) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    func splitViewControllerPreferredInterfaceOrientationForPresentation(_ splitViewController: UISplitViewController) -> UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
}
