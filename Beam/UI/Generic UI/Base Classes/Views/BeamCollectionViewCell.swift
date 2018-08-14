//
//  BeamCollectionViewCell.swift
//  beam
//
//  Created by Robin Speijer on 28-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamCollectionViewCell: UICollectionViewCell, DynamicDisplayModeView {
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil {
            selectedBackgroundView = UIView(frame: bounds)
            selectedBackgroundView?.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
            registerForDisplayModeChangeNotifications()
        } else {
            selectedBackgroundView = nil
            unregisterForDisplayModeChangeNotifications()
        }
    }
    
    deinit {
        unregisterForDisplayModeChangeNotifications()
    }
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        switch displayMode {
        case .default:
            backgroundColor = UIColor.white
            selectedBackgroundView?.backgroundColor = UIColor.beamGreyExtraExtraLight()
        case .dark:
            backgroundColor = UIColor.beamDarkContentBackgroundColor()
            selectedBackgroundView?.backgroundColor = UIColor.beamGreyDark()
        }
        
        contentView.backgroundColor = backgroundColor
    }
    
}
