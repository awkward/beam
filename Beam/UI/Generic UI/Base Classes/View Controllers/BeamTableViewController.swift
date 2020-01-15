//
//  BeamTableViewController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamTableViewController: UITableViewController, DynamicDisplayModeView, NoticeHandling {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BeamTableViewController.displayModeDidChangeNotification(_:)), name: .DisplayModeDidChange, object: nil)
        displayModeDidChangeAnimated(false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .DisplayModeDidChange, object: nil)
    }
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        switch displayMode {
        case .default:
            view.backgroundColor = tableView.style == .grouped ? .systemGroupedBackground : .white
            tableView.separatorColor = .beamTableViewSeperatorColor()
            tableView.sectionIndexBackgroundColor = .beamBarColor()
            tableView.sectionIndexColor = .beamColor()
        case .dark:
            view.backgroundColor = tableView.style == .grouped ? .beamDarkBackgroundColor() : .beamDarkContentBackgroundColor()
            tableView.separatorColor = .beamDarkTableViewSeperatorColor()
            tableView.sectionIndexBackgroundColor = .beamDarkContentBackgroundColor()
            tableView.sectionIndexColor = .beamPurpleLight()
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
