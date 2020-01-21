//
//  ContinueCommentThreadCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 29-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class ContinueCommentThreadCell: BaseCommentCell {

    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var iconImageView: UIImageView!
    
    var loading = false
    
    override func reloadContents() {
        super.reloadContents()
        
        self.titleLabel.text = AWKLocalizedString("continue-comment-thread")
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        let tintColor = AppearanceValue(light: UIColor.beam, dark: UIColor.beamPurpleLight)
        self.titleLabel.textColor = tintColor
        if self.iconImageView.tintColor != tintColor {
            self.iconImageView.tintColor = tintColor
        }
    }

}
