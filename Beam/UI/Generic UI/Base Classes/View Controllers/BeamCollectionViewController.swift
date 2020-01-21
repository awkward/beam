//
//  BeamCollectionViewController.swift
//  beam
//
//  Created by Robin Speijer on 17-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class BeamCollectionViewController: UICollectionViewController, BeamAppearance, NoticeHandling {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = AppearanceValue(light: .systemGroupedBackground, dark: .beamDarkBackground)
        
        appearanceDidChange()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            appearanceDidChange()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            return .all
        }
        return .portrait
    }

}
