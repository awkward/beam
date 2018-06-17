//
//  AddImagesCollectionViewCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

@IBDesignable
class AddImagesIconView: BeamView {
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        //// Color Declarations
        let fillColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        
        //// Plus Drawing
        let plusPath = UIBezierPath()
        plusPath.move(to: CGPoint(x: 13, y: 11))
        plusPath.addLine(to: CGPoint(x: 13, y: 0))
        plusPath.addLine(to: CGPoint(x: 11, y: 0))
        plusPath.addLine(to: CGPoint(x: 11, y: 11))
        plusPath.addLine(to: CGPoint(x: 0, y: 11))
        plusPath.addLine(to: CGPoint(x: 0, y: 13))
        plusPath.addLine(to: CGPoint(x: 11, y: 13))
        plusPath.addLine(to: CGPoint(x: 11, y: 24))
        plusPath.addLine(to: CGPoint(x: 13, y: 24))
        plusPath.addLine(to: CGPoint(x: 13, y: 13))
        plusPath.addLine(to: CGPoint(x: 24, y: 13))
        plusPath.addLine(to: CGPoint(x: 24, y: 11))
        plusPath.addLine(to: CGPoint(x: 13, y: 11))
        plusPath.close()
        plusPath.usesEvenOddFillRule = true
        
        fillColor.setFill()
        plusPath.fill()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 24, height: 24)
    }
}

class AddImagesCollectionViewCell: BeamCollectionViewCell {
    
    @IBOutlet var iconView: AddImagesIconView!
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let backgroundColor = DisplayModeValue(UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0), darkValue: UIColor(red: 38 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1.0))
        self.iconView.isOpaque = true
        self.iconView.backgroundColor = backgroundColor
        
        self.contentView.isOpaque = true
        self.contentView.backgroundColor = backgroundColor
    }
}
