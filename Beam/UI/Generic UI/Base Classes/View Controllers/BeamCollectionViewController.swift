//
//  BeamCollectionViewController.swift
//  beam
//
//  Created by Robin Speijer on 17-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class BeamCollectionViewController: UICollectionViewController, DynamicDisplayModeView, NoticeHandling {

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
            collectionView?.backgroundColor = UIColor.groupTableViewBackground
        case .dark:
            collectionView?.backgroundColor = UIColor.beamDarkBackgroundColor()
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
