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
            self.displayModeDidChange()
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        if let placeholder: String = self.placeholder {
            let placeholderColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
            self.textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        } else {
            self.textField.attributedPlaceholder = nil
        }
        
        self.textField.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
    }

}
