//
//  BeamViewController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamViewController: UIViewController, DynamicDisplayModeView, NoticeHandling {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForDisplayModeChangeNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterForDisplayModeChangeNotifications()
    }
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        switch displayMode {
        case .default:
            self.view.backgroundColor = UIColor.groupTableViewBackground
        case .dark:
            self.view.backgroundColor = UIColor.beamDarkBackgroundColor()
        }
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return displayMode == .dark ? UIStatusBarStyle.lightContent: UIStatusBarStyle.default
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            return .all
        }
        return .portrait
    }

}
