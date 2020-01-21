//
//  CollectionViewLoaderFooterView.swift
//  Beam
//
//  Created by Rens Verhoeven on 01-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class CollectionViewLoaderFooterView: BeamCollectionReusableView {
    
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    func appearanceDidChange() {
        self.activityIndicatorView.color = AppearanceValue(light: UIColor.lightGray, dark: UIColor.white)
    }

}
