//
//  SmallTabBarController.swift
//  beam
//
//  Created by Rens Verhoeven on 20-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class SmallTabBarController: BeamTabBarController {
    
    var tabBarHeight: CGFloat = 44
    var verticalImageOffset: CGFloat = 5;
    
    func adjustTabBarItems() {
        
        for item in self.tabBar.items! {
            item.title = nil
            item.imageInsets = UIEdgeInsets(top: self.verticalImageOffset, left: 0, bottom: -self.verticalImageOffset, right: 0)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.adjustTabBarItems()
        var tabbarFrame = self.tabBar.frame;
        tabbarFrame.origin.y = self.view.bounds.height - (self.tabBarHeight + view.safeAreaInsets.bottom)
        tabbarFrame.size.height = (self.tabBarHeight + view.safeAreaInsets.bottom)
        self.tabBar.frame = tabbarFrame;
    }
}
