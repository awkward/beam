//
//  PostMediaOverviewCollectionViewCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 04-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class PostMediaOverviewCollectionViewCell: MediaOverviewCollectionViewCell {

    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        self.mediaImageView.isOpaque = true
        self.mediaImageView.backgroundColor = AppearanceValue(light: UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1), dark: UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1))
        //self.progressView.color = displayMode == .Dark ?  UIColor.white: UIColor.beamGreyExtraLight
    }
}
