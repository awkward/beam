//
//  CameraCollectionViewCell.swift
//  AWKImagePickerControllerExample
//
//  Created by Rens Verhoeven on 30-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit

@IBDesignable
class CameraIconView: UIView {
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let color = self.tintColor
        
        //// Body Drawing
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: 12, y: 3))
        bodyPath.addLine(to: CGPoint(x: 2, y: 3))
        bodyPath.addCurve(to: CGPoint(x: 0, y: 4.99), controlPoint1: CGPoint(x: 0.89, y: 3), controlPoint2: CGPoint(x: 0, y: 3.89))
        bodyPath.addLine(to: CGPoint(x: 0, y: 31.01))
        bodyPath.addCurve(to: CGPoint(x: 2, y: 33), controlPoint1: CGPoint(x: 0, y: 32.1), controlPoint2: CGPoint(x: 0.89, y: 33))
        bodyPath.addLine(to: CGPoint(x: 38, y: 33))
        bodyPath.addCurve(to: CGPoint(x: 40, y: 31.01), controlPoint1: CGPoint(x: 39.11, y: 33), controlPoint2: CGPoint(x: 40, y: 32.11))
        bodyPath.addLine(to: CGPoint(x: 40, y: 4.99))
        bodyPath.addCurve(to: CGPoint(x: 38.01, y: 3), controlPoint1: CGPoint(x: 40, y: 3.9), controlPoint2: CGPoint(x: 39.11, y: 3))
        bodyPath.addLine(to: CGPoint(x: 28, y: 3))
        bodyPath.addCurve(to: CGPoint(x: 27.44, y: 2.17), controlPoint1: CGPoint(x: 28, y: 3), controlPoint2: CGPoint(x: 27.53, y: 2.31))
        bodyPath.addCurve(to: CGPoint(x: 26.54, y: 0.83), controlPoint1: CGPoint(x: 27.16, y: 1.75), controlPoint2: CGPoint(x: 26.54, y: 0.83))
        bodyPath.addCurve(to: CGPoint(x: 24.98, y: 0), controlPoint1: CGPoint(x: 26.23, y: 0.37), controlPoint2: CGPoint(x: 25.54, y: 0))
        bodyPath.addLine(to: CGPoint(x: 14.99, y: 0))
        bodyPath.addCurve(to: CGPoint(x: 13.43, y: 0.84), controlPoint1: CGPoint(x: 14.44, y: 0), controlPoint2: CGPoint(x: 13.74, y: 0.37))
        bodyPath.addLine(to: CGPoint(x: 12, y: 3))
        bodyPath.close()
        bodyPath.move(to: CGPoint(x: 20, y: 28))
        bodyPath.addCurve(to: CGPoint(x: 30, y: 18), controlPoint1: CGPoint(x: 25.52, y: 28), controlPoint2: CGPoint(x: 30, y: 23.52))
        bodyPath.addCurve(to: CGPoint(x: 20, y: 8), controlPoint1: CGPoint(x: 30, y: 12.48), controlPoint2: CGPoint(x: 25.52, y: 8))
        bodyPath.addCurve(to: CGPoint(x: 10, y: 18), controlPoint1: CGPoint(x: 14.48, y: 8), controlPoint2: CGPoint(x: 10, y: 12.48))
        bodyPath.addCurve(to: CGPoint(x: 20, y: 28), controlPoint1: CGPoint(x: 10, y: 23.52), controlPoint2: CGPoint(x: 14.48, y: 28))
        bodyPath.close()
        bodyPath.move(to: CGPoint(x: 34.5, y: 10))
        bodyPath.addCurve(to: CGPoint(x: 36, y: 8.5), controlPoint1: CGPoint(x: 35.33, y: 10), controlPoint2: CGPoint(x: 36, y: 9.33))
        bodyPath.addCurve(to: CGPoint(x: 34.5, y: 7), controlPoint1: CGPoint(x: 36, y: 7.67), controlPoint2: CGPoint(x: 35.33, y: 7))
        bodyPath.addCurve(to: CGPoint(x: 33, y: 8.5), controlPoint1: CGPoint(x: 33.67, y: 7), controlPoint2: CGPoint(x: 33, y: 7.67))
        bodyPath.addCurve(to: CGPoint(x: 34.5, y: 10), controlPoint1: CGPoint(x: 33, y: 9.33), controlPoint2: CGPoint(x: 33.67, y: 10))
        bodyPath.close()
        bodyPath.usesEvenOddFillRule = true
        
        color?.setFill()
        bodyPath.fill()
        
        //// Lens Drawing
        let lensPath = UIBezierPath(ovalIn: CGRect(x: 12, y: 10, width: 16, height: 16))
        color?.setFill()
        lensPath.fill()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 40, height: 33)
    }
    
}

class CameraCollectionViewCell: UICollectionViewCell, ColorPaletteSupport {
    
    class var reuseIdentifier: String {
        return "camera-cell"
    }
    
    @IBOutlet var iconView: CameraIconView!
    
    deinit {
        self.stopColorPaletteSupport()
    }
    
    weak var assetsPickerController: AssetsPickerController? {
        didSet {
            self.startColorPaletteSupport()
        }
    }
    
    func colorPaletteDidChange() {
        self.contentView.backgroundColor = self.colorPalette.assetCellBackgroundColor
        self.iconView.tintColor = self.colorPalette.cameraIconColor
    }
    
}
