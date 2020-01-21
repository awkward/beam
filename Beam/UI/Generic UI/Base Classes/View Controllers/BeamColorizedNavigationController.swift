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
        
        navigationBar.isTranslucent = false
        navigationBar.tintColor = AppearanceValue(light: .white, dark: .beamPurpleLight)
        navigationBar.barTintColor = UIColor(named: "colorized_bar")
        
        var titleAttributes = navigationBar.titleTextAttributes ?? [NSAttributedString.Key: Any]()
        titleAttributes[NSAttributedString.Key.foregroundColor] = UIColor.white
        navigationBar.titleTextAttributes = titleAttributes
    }

}
