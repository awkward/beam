//
//  BeamCollectionReusableView.swift
//  Beam
//
//  Created by Rens Verhoeven on 01-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamCollectionReusableView: UICollectionReusableView, DynamicDisplayModeView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.registerForDisplayModeChangeNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        self.unregisterForDisplayModeChangeNotifications()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.displayModeDidChange()
        self.registerForDisplayModeChangeNotifications()
    }
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        self.displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        
    }
    
}
