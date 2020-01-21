//
//  SettingsTableViewCell.swift
//  beam
//
//  Created by Rens Verhoeven on 13-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class SettingsTableViewCell: BeamTableViewCell {
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        self.detailTextLabel?.textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.5)
    }

}
