//
//  ColorizedNavigationController.swift
//  beam
//
//  Created by Robin Speijer on 21-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamColorizedNavigationController: BeamNavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.tintColor = AppearanceValue(light: .white, dark: .beamPurpleLight)
        navigationBar.standardAppearance.configureColorizedBeamAppearance()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
}
