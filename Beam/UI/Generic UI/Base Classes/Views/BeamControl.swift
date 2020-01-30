//
//  BeamControl.swift
//  beam
//
//  Created by Rens Verhoeven on 30-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamControl: UIControl, BeamAppearance {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.appearanceDidChange()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            appearanceDidChange()
        }
    }
    
    func appearanceDidChange() {
        switch self.userInterfaceStyle {
        case .dark:
            self.tintColor = UIColor.beamPurpleLight
        default:
            self.tintColor = UIColor.beam
        }
    }
}
