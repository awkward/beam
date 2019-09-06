//
//  UIAlertController+Convience.swift
//  Beam
//
//  Created by Rens Verhoeven on 04-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    convenience init(alertWithCloseButtonAndTitle title: String, message: String) {
        self.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        self.addAction(UIAlertAction(title: AWKLocalizedString("close-button"), style: UIAlertAction.Style.cancel, handler: nil))
    }
    
}
