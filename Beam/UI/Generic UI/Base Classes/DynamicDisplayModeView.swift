//
//  DynamicDisplayModeView.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

/** Protocol to implement to support different display modes like dark mode. This has been implemented by default by all beam base views/viewcontrollers.

    To implement this protocol, you need to listen for Notification.Name.DisplayModeDidChange notifications. When the notification fires, call displayModeDidChange(newMode: animated:). Implement displayModeDidChange to update UI elements according to the display mode. This method will be called within an animation block whenever appropiate.
*/
protocol DynamicDisplayModeView: class {
    
    var displayMode: DisplayMode { get }
    
    func registerForDisplayModeChangeNotifications()
    func unregisterForDisplayModeChangeNotifications()
    
    /// Listen to this notification and call displayModeDidChange(newMode: DisplayMode, animated: Bool) in it.
    func displayModeDidChangeNotification(_ notification: Notification)
    
    /// Called by displayModeDidChangeNotification() when the display mode has been changed. This method will call displayModeDidChange(:) in an animation block if animated is true, otherwise it will call it directly.
    func displayModeDidChangeAnimated(_ animated: Bool)

    /// When the display mode (dark or regular mode) has been changed, this method will be called. It will be embedded in an animation block if appropiate.
    func displayModeDidChange()
}

extension DynamicDisplayModeView {
    
    func registerForDisplayModeChangeNotifications() {
        NotificationCenter.default.addObserver(self, selector: Selector("displayModeDidChangeNotification:"), name: .DisplayModeDidChange, object: nil)
        displayModeDidChangeAnimated(false)
    }
    
    func unregisterForDisplayModeChangeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .DisplayModeDidChange, object: nil)
    }
    
    func displayModeDidChangeAnimated(_ animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { () -> Void in
                self.displayModeDidChange()
                }, completion: nil)
        } else {
            displayModeDidChange()
        }
    }
    
    var displayMode: DisplayMode {
        #if TARGET_INTERFACE_BUILDER
            return DisplayMode.Default
        #endif
        return AppDelegate.shared.displayModeController.currentMode
    }
    
}
