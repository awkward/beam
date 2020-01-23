//
//  UIBarAppearance+Beam.swift
//  beam
//
//  Created by Robin Speijer on 22/01/2020.
//  Copyright © 2020 Awkward. All rights reserved.
//

import UIKit

extension UIBarAppearance {
    
    @objc func configureBeamAppearance() {
        configureWithOpaqueBackground()
        backgroundColor = .beamBar
    }
    
    @objc func configureColorizedBeamAppearance() {
        configureWithOpaqueBackground()
        backgroundColor = .beamColorizedBar
        shadowColor = nil
    }
    
}

extension UINavigationBarAppearance {
    
    override func configureBeamAppearance() {
        super.configureBeamAppearance()
        titleTextAttributes = [.foregroundColor: UIColor.label]
        largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    override func configureColorizedBeamAppearance() {
        super.configureColorizedBeamAppearance()
        titleTextAttributes = [.foregroundColor: UIColor.white]
        largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
}
