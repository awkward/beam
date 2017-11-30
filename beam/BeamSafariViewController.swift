//
//  BeamSafariViewController.swift
//  beam
//
//  Created by Robin Speijer on 16-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import SafariServices

/// Fix for the SafariViewController bug introducted in 9.2: https://gist.github.com/alexruperez/ab5e175d40413faea0a8
class BeamSafariViewController: SFSafariViewController {
    
    init(url URL: URL) {
        super.init(url: URL, entersReaderIfAvailable: UserSettings[.prefersSafariViewControllerReaderMode])
        if #available(iOS 10.0, *), AppDelegate.shared.displayModeController.currentMode == .dark {
            self.preferredBarTintColor = UIColor.black
            self.preferredControlTintColor = UIColor.white
        }
    }
    
    override init(url URL: URL, entersReaderIfAvailable: Bool) {
        super.init(url: URL, entersReaderIfAvailable: entersReaderIfAvailable)
        if #available(iOS 10.0, *), AppDelegate.shared.displayModeController.currentMode == .dark {
            self.preferredBarTintColor = UIColor.black
            self.preferredControlTintColor = UIColor.white
        }
    }
    
    var isSwipingBack = false {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        if self.isSwipingBack && self.presentingViewController != nil {
            return self.presentingViewController!.preferredStatusBarStyle
        }
        return super.preferredStatusBarStyle
    }
    
    override var prefersStatusBarHidden : Bool {
        if self.isSwipingBack && self.presentingViewController != nil {
            return self.presentingViewController!.prefersStatusBarHidden
        }
        return super.prefersStatusBarHidden
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.isSwipingBack = true
        
        self.transitionCoordinator?.notifyWhenInteractionEnds({ (context) in
            self.isSwipingBack = false
        })
        
        super.viewWillDisappear(animated)
    }

}
