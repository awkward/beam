//
//  UISearchBar+UITextField.swift
//  beam
//
//  Created by David van Leeuwen on 14/10/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

extension UISearchBar {
    
    fileprivate var textField: UITextField? {
        for subview in self.subviews {
            for secondSubview in subview.subviews {
                if secondSubview.isKind(of: UITextField.self), let textfield = secondSubview as? UITextField {
                    return textfield
                }
            }
        }
        return nil
    }
    
    var textColor: UIColor? {
        get {
            return self.textField?.textColor
        }
        set {
            self.textField?.textColor = newValue

        }
    }
    
}
