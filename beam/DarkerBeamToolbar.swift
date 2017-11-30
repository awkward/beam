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
        
        self.isTranslucent = false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isTranslucent = false
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.barTintColor = self.displayMode == .dark ? UIColor.beamDarkContentBackgroundColor() : UIColor.beamBarColor()
    }

}
