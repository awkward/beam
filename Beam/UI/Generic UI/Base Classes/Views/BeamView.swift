//
//  BeamView.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamView: UIView, BeamAppearance {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .beamContentBackground
        appearanceDidChange()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            appearanceDidChange()
        }
    }
    
    func appearanceDidChange() {}

}
