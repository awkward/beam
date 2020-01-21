//
//  DarkerBeamToolbar.swift
//  Beam
//
//  Created by Rens Verhoeven on 02-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class DarkerBeamToolbar: BeamToolbar {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    private func setupView() {
        self.preservesSuperviewLayoutMargins = false
        self.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        self.isTranslucent = false
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        self.barTintColor = self.userInterfaceStyle == .dark ? UIColor.beamDarkContentBackground : UIColor.beamBar
    }

}
