//
//  SubredditFilteringTextFieldTableViewCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 01-09-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class SubredditFilteringTextFieldTableViewCell: BeamTableViewCell {

    @IBOutlet fileprivate var textField: UITextField!
    
    var placeholder: String? {
        didSet {
            self.appearanceDidChange()
        }
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        if let placeholder: String = self.placeholder {
            let placeholderColor = AppearanceValue(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.5)
            self.textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
        } else {
            self.textField.attributedPlaceholder = nil
        }
        
        self.textField.textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
    }

}
