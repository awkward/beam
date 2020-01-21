//
//  BeamCollectionViewCell.swift
//  beam
//
//  Created by Robin Speijer on 28-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamCollectionViewCell: UICollectionViewCell, BeamAppearance {
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil {
            selectedBackgroundView = UIView(frame: bounds)
            selectedBackgroundView?.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        } else {
            selectedBackgroundView = nil
        }
    }
    
    func appearanceDidChange() {
        switch userInterfaceStyle {
        case .dark:
            backgroundColor = UIColor.beamDarkContentBackground
            selectedBackgroundView?.backgroundColor = UIColor.beamGreyDark
        default:
            backgroundColor = UIColor.white
            selectedBackgroundView?.backgroundColor = UIColor.beamGreyExtraExtraLight
        
        }
        
        contentView.backgroundColor = backgroundColor
    }
    
}
