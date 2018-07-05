//
//  FavoritesExplanationView.swift
//  beam
//
//  Created by Rens Verhoeven on 02-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class FavoritesExplanationView: BeamView {
    
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var iconImageView: UIImageView!
    
    var closeHandler: ((_ button: UIButton) -> Void)?

    override func displayModeDidChange() {
        super.displayModeDidChange()
    
        switch self.displayMode {
        case .dark:
            self.textLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            self.closeButton.tintColor = UIColor.white.withAlphaComponent(0.4)
        case .default:
            self.textLabel.textColor = UIColor(red: 62 / 255, green: 61 / 255, blue: 66 / 255, alpha: 1.0)
            self.closeButton.tintColor = UIColor.black.withAlphaComponent(0.4)
        }
        
        self.setNeedsDisplay()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.iconImageView.layer.cornerRadius = self.iconImageView.bounds.height / 2
        self.iconImageView.layer.masksToBounds = true
    }
    
    override func draw(_ rect: CGRect) {
        let seperatorHeight = 1 / UIScreen.main.scale
        let seperatorRect = CGRect(x: 0, y: rect.maxY - seperatorHeight, width: rect.width, height: seperatorHeight)
        let seperatorColor = self.displayMode == .dark ? UIColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1) : UIColor(red: 0.84, green: 0.83, blue: 0.85, alpha: 1)
        
        let seperatorPath = UIBezierPath(rect: seperatorRect)
        seperatorColor.setFill()
        seperatorPath.fill()
    }

    @IBAction func closeTapped(_ sender: AnyObject) {
        self.closeHandler?(self.closeButton)
    }
    
}
