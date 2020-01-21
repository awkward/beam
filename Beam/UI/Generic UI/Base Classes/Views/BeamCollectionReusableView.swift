//
//  BeamCollectionReusableView.swift
//  Beam
//
//  Created by Rens Verhoeven on 01-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamCollectionReusableView: UICollectionReusableView, BeamAppearance {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.appearanceDidChange()
    }
    
}
