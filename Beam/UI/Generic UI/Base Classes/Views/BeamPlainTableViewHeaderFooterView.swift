//
//  BeamPlainTableViewHeaderFooterView.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamPlainTableViewHeaderFooterView: UITableViewHeaderFooterView, DynamicDisplayModeView {
    
    var titleFont: UIFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold) {
        didSet {
            self.displayModeDidChange()
        }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.registerForDisplayModeChangeNotifications()
        self.displayModeDidChange()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.registerForDisplayModeChangeNotifications()
        self.displayModeDidChange()
    }
    
    deinit {
        self.unregisterForDisplayModeChangeNotifications()
    }
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        self.displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        switch self.displayMode {
        case .default:
            self.contentView.backgroundColor = UIColor.beamPlainSectionHeaderColor()
        case .dark:
            self.contentView.backgroundColor = UIColor.beamDarkBackgroundColor()
        }
        self.textLabel?.textColor = UIColor.beamGreyLight()
        self.textLabel?.font = self.titleFont
    }
    
    //This fixes a bug where the font is never changed
    override func layoutSubviews() {
        super.layoutSubviews()
        self.displayModeDidChange()
    }

}
