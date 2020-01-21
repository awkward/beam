//
//  BeamAppearance.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

/** Protocol to implement to support different display modes like dark mode. This has been implemented by default by all beam base views/viewcontrollers.

    To implement this protocol, you need to listen for Notification.Name.DisplayModeDidChange notifications. When the notification fires, call displayModeDidChange(newMode: animated:). Implement displayModeDidChange to update UI elements according to the display mode. This method will be called within an animation block whenever appropiate.
*/
protocol BeamAppearance: UITraitEnvironment {
    
    /// When the display mode (dark or regular mode) has been changed, this method will be called. It will be embedded in an animation block if appropiate.
    func appearanceDidChange()
    
}

extension BeamAppearance {
    
    func appearanceDidChange() {}
    
    var userInterfaceStyle: UIUserInterfaceStyle { traitCollection.userInterfaceStyle }
    
}
