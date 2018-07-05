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
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.activityIndicatorView.color = DisplayModeValue(UIColor.lightGray, darkValue: UIColor.white)
    }

}
