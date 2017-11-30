//
//  ColorizedNavigationController.swift
//  beam
//
//  Created by Robin Speijer on 21-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamColorizedNavigationController: BeamNavigationController {

    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.navigationBar.isTranslucent = false
        
        var titleAttributes = navigationBar.titleTextAttributes ?? [String: AnyObject]()
        titleAttributes[NSForegroundColorAttributeName] = UIColor.white
        self.navigationBar.titleTextAttributes = titleAttributes
        
        switch displayMode {
        case .default:
            self.navigationBar.barTintColor = UIColor.beamPurple()
            self.navigationBar.tintColor = UIColor.white
        case .dark:
            self.navigationBar.barTintColor = UIColor.beamDarkContentBackgroundColor()
            self.navigationBar.tintColor = UIColor.beamPurpleLight()
        }
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func embeddedLayout() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: self.contentInset.bottom, right: 0)
    }

}
