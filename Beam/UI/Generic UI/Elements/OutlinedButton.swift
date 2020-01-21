//
//  OutlinedButton.swift
//  Beam
//
//  Created by Rens Verhoeven on 17-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class OutlinedButton: BeamButton {
    
    @IBInspectable var titleColor: UIColor = UIColor.white {
        didSet {
            self.appearanceDidChange()
        }
    }
    
    override func setupButton() {
        super.setupButton()
        
        self.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)
    }
    
    var isOutlined: Bool {
        get {
            return self.layer.borderWidth > 0
        }
        set {
            self.layer.borderWidth = newValue ? 1: 0
        }
    }

    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        self.layer.borderColor = self.titleColor.cgColor
        if self.titleColor(for: UIControl.State()) != nil {
            self.setTitleColor(self.titleColor, for: UIControl.State())
        }
        self.backgroundColor = UIColor.clear
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        self.appearanceDidChange()
    }
    
}
