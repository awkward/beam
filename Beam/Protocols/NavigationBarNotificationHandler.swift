//
//  NavigationBarNotificationHandler.swift
//  beam
//
//  Created by Rens Verhoeven on 30-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

/*!
@protocol NavigationBarNotificationDisplayingDelegate

A protocol to supply a custom view to display the notification below.
*/
protocol NavigationBarNotificationDisplayingDelegate: class {
    
    func topViewForDisplayOfnotificationView<NotificationView: UIView>(_ view: NotificationView) -> UIView? where NotificationView: NavigationBarNotification
}

/*!
@protocol NavigationBarNotification

A protocol to implement for all views that display as notifications under navigation bars
*/
protocol NavigationBarNotification: class {
    
    //This constaint is used for animiting the notification. It connecyts the bottom of the notification view to the bottom of the top view.
    var bottomNotificationConstraint: NSLayoutConstraint? { get set }
    
    //The delay for auto dismissing the notification view, if it's 0 the view will stay on screen permenantly. The default is 3
    var autoDismissalDelay: TimeInterval { get }
    
    //The view to display the view below
    var displayView: UIView? { get }
    
    //Hide and remove the notification. This is implemented by default
    func dismiss()
}

var notificationIsActive: Bool = false

extension NavigationBarNotification where Self: UIView {
    
    var autoDismissalDelay: TimeInterval {
        return 3
    }
    
    var displayView: UIView? {
        return nil
    }
    
    func dismiss() {
        if let superView = self.superview {
            UIView.animate(withDuration: 0.32, animations: { () -> Void in
                self.bottomNotificationConstraint?.isActive = true
                //Also here the next line is required, otherwise the animation will not work as smoothly
                superView.layoutIfNeeded()
                }, completion: { (_) in
                    self.removeFromSuperview()
                    self.removeConstraints(self.constraints)
                    notificationIsActive = false
            })
        }
    }
}

enum NavigationBarNotificationStyle {
    case fullWidth
    case free
}

extension UINavigationController {
    
    /*!
    Present a notification under a certain view, by default this is the Navigation Bar of the top most UINavigationController, but in some cases this may be a different view. To supply a different view, use the NavigationBarNotificationDisplayingDelegate protocol
    
    @param view The notification view that implements the NavigationBarNotification protocol
    @param style The style the notification view is being displayed, free will snap it only to the top and center it horizontally, full width will snap it to the top and sides. Defaults to FullWidth
    @param insets The edge insets to display the notification. This can be handy when using the free style it will allow a space between the top view and the notification view. Defaults to none (all zero)
    */
    func presentNotificationView<NotificationView: UIView>(_ view: NotificationView, style: NavigationBarNotificationStyle = .fullWidth, insets: UIEdgeInsets = UIEdgeInsets()) where NotificationView: NavigationBarNotification {
        if notificationIsActive {
            return
        }
        notificationIsActive = true
        var topView: UIView = self.navigationBar
        if let viewController = self.findTopViewController(self.topViewController) as? NavigationBarNotificationDisplayingDelegate, let view = viewController.topViewForDisplayOfnotificationView(view) {
            topView = view
        }
        if let displayView = view.displayView {
            topView = displayView
        }
        if let superView = topView.superview {
            superView.insertSubview(view, belowSubview: topView)
            view.translatesAutoresizingMaskIntoConstraints = false
            switch style {
            case .fullWidth:
                self.addConstraintsForFullWidth(view, superView: superView, topView: topView, insets: insets)
            case .free:
                self.addConstraintsForFreePlacement(view, superView: superView, topView: topView, insets: insets)
            }
            //The next line is required, otherwise the animation will not work as smoothly
            superView.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.32, delay: 0, options: [], animations: { () -> Void in
                view.bottomNotificationConstraint!.isActive = false
                //Also here the next line is required, otherwise the animation will not work as smoothly
                superView.layoutIfNeeded()
                }, completion: { (_) in
                    self.checkForAutoDismissal(view)
            })
        } else {
            print("The message was not displayed, because the superView was missing")
        }
    }
    
    fileprivate func checkForAutoDismissal<NotificationView: UIView>(_ view: NotificationView) where NotificationView: NavigationBarNotification {
        if view.autoDismissalDelay <= 0 {
            return
        }
        let delayTime = DispatchTime.now() + Double(Int64(view.autoDismissalDelay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            view.dismiss()
        }
    }
    
    fileprivate func addConstraintsForFullWidth<NotificationView: UIView>(_ view: NotificationView, superView: UIView, topView: UIView, insets: UIEdgeInsets) where NotificationView: NavigationBarNotification {
        let topConstraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: topView, attribute: .bottom, multiplier: 1.0, constant: insets.top)
        topConstraint.priority = UILayoutPriority.defaultLow
        superView.addConstraint(topConstraint)
        
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: topView, attribute: .bottom, multiplier: 1.0, constant: 0)
        bottomConstraint.priority = UILayoutPriority.required
        superView.addConstraint(bottomConstraint)
        view.bottomNotificationConstraint = bottomConstraint
        
        superView.addConstraint(NSLayoutConstraint(item: superView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: insets.right))
        superView.addConstraint(NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: superView, attribute: .left, multiplier: 1.0, constant: insets.left))
    }
    
    fileprivate func addConstraintsForFreePlacement<NotificationView: UIView>(_ view: NotificationView, superView: UIView, topView: UIView, insets: UIEdgeInsets) where NotificationView: NavigationBarNotification {
        let topConstraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: topView, attribute: .bottom, multiplier: 1.0, constant: insets.top)
        topConstraint.priority = UILayoutPriority.defaultLow
        superView.addConstraint(topConstraint)
        
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: topView, attribute: .bottom, multiplier: 1.0, constant: 0)
        bottomConstraint.priority = UILayoutPriority.required
        superView.addConstraint(bottomConstraint)
        view.bottomNotificationConstraint = bottomConstraint
        
        superView.addConstraint(NSLayoutConstraint(item: superView, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: view, attribute: .right, multiplier: 1.0, constant: insets.right))
        superView.addConstraint(NSLayoutConstraint(item: view, attribute: .left, relatedBy: .greaterThanOrEqual, toItem: superView, attribute: .left, multiplier: 1.0, constant: insets.left))
        superView.addConstraint(NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1.0, constant: 0))
    }
    
    fileprivate func findTopViewController(_ viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return self.findTopViewController(navigationController)
        } else if let tabBarController = viewController as? UITabBarController {
            return self.findTopViewController(tabBarController.selectedViewController)
        } else if let subreddditViewController = viewController as? SubredditTabBarController {
            return self.findTopViewController(subreddditViewController)
        } else {
            return viewController
        }
    }
}
