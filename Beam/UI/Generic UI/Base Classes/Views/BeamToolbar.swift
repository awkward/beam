//
//  BeamToolbar.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamToolbar: UIToolbar, DynamicDisplayModeView {
    
    //Overriding drawRect in UIToolbar, UITabBar or UINavigationBar disables the background blur. That's why I use views that overlay the border
    var topBorderOverlay: UIView = {
        let view = UIView()
        return view
    }()
    
    var bottomBorderOverlay: UIView = {
        let view = UIView()
        return view
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.registerForDisplayModeChangeNotifications()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.registerForDisplayModeChangeNotifications()
    }
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        self.displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        self.barTintColor = self.displayMode == .dark ? UIColor.beamDarkBackgroundColor() : UIColor.beamBarColor()
        
        let borderColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
        self.topBorderOverlay.backgroundColor = borderColor
        self.bottomBorderOverlay.backgroundColor = borderColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.topBorderOverlay.superview == nil {
            self.addSubview(self.topBorderOverlay)
            self.addSubview(self.bottomBorderOverlay)
        }
        
        let borderHeight: CGFloat = 1.0 / UIScreen.main.scale
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: borderHeight)
        self.layer.shadowOpacity = 0.05
        self.layer.shadowRadius = 1
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        
        self.topBorderOverlay.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: borderHeight)
        self.bottomBorderOverlay.frame = CGRect(x: 0, y: self.bounds.maxY, width: self.bounds.width, height: borderHeight)
    }
    
}
