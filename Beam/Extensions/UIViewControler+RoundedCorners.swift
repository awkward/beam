//
//  UIViewControler+RoundedCorners.swift
//  beam
//
//  Created by Rens Verhoeven on 19-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

extension UIViewController {

    var usesRoundedCorners: Bool {
        set {
            self.view.layer.masksToBounds = newValue
            self.view.layer.cornerRadius = (newValue ? 6: 0)
        }
        get {
            return self.view.layer.cornerRadius > 0
        }
    }
    
}
