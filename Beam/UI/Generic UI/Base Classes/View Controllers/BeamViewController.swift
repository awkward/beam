//
//  BeamViewController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamViewController: UIViewController, BeamAppearance, NoticeHandling {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appearanceDidChange()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            appearanceDidChange()
        }
    }
    
    func appearanceDidChange() {
        view.backgroundColor = AppearanceValue(light: .systemGroupedBackground, dark: .beamDarkBackground)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            return .all
        }
        return .portrait
    }
    
}
