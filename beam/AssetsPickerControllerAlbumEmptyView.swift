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
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.backgroundColor = DisplayModeValue(UIColor.beamBackground(), darkValue: UIColor.beamDarkContentBackgroundColor())
        self.titleLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.descriptionLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
    }
}
