//
//  BeamAppearance.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

/// Legacy protocol implemented by UI elements in the app to update UI elements
/// upon userInterfaceStyle changes. This has been implemented by default by all
/// beam base views/viewcontrollers.
///
/// Don't implement this protocol in new UI elements. Use colors with different
/// appearance values, and listen to UITraitEnvironment changes.
protocol BeamAppearance: UITraitEnvironment {
    
    /// Method to be called on userInterfaceStyle changes in `traitCollectionDidChange`.
    func appearanceDidChange()
    
}

extension BeamAppearance {
    func appearanceDidChange() {}
    var userInterfaceStyle: UIUserInterfaceStyle { traitCollection.userInterfaceStyle }
}
