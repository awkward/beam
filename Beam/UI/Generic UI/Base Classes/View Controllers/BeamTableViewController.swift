//
//  BeamTableViewController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamTableViewController: UITableViewController, BeamAppearance, NoticeHandling {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            appearanceDidChange()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appearanceDidChange()
    }
    
    func appearanceDidChange() {
        if tableView.style == .grouped {
            tableView.backgroundColor = AppearanceValue(light: UIColor.systemGroupedBackground, dark: UIColor.beamDarkBackground)
        } else {
            tableView.backgroundColor = AppearanceValue(light: UIColor.white, dark: UIColor.beamDarkContentBackground)
        }
        tableView.separatorColor = AppearanceValue(light: .beamTableViewSeperator, dark: .beamDarkTableViewSeperator)
        tableView.sectionIndexBackgroundColor = .beamBar
        tableView.sectionIndexColor = .beam
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            return .all
        }
        return .portrait
    }
}
