//
//  AssetsPickerControllerAlbumEmptyView.swift
//  Beam
//
//  Created by Rens Verhoeven on 14-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class AssetsPickerControllerAlbumEmptyView: BeamView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.reloadContents()
    }
    
    fileprivate func reloadContents() {
        self.titleLabel.text = AWKLocalizedString("assets-picker-empty-title")
        self.descriptionLabel.text = AWKLocalizedString("assets-picker-empty-message")
       
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        self.backgroundColor = AppearanceValue(light: UIColor.beamBackground, dark: UIColor.beamDarkContentBackground)
        self.titleLabel.textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
        self.descriptionLabel.textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
    }
}
