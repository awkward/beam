//
//  SelectionIconView.swift
//  AWKImagePickerControllerExample
//
//  Created by Rens Verhoeven on 29-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit

@IBDesignable
class SelectionIconView: UIView {

    @IBInspectable var color = UIColor.white {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        
        //// Color Declarations
        let shadowColor = UIColor.black
        
        //// Shadow Declarations
        let shadow = NSShadow()
        shadow.shadowColor = shadowColor.withAlphaComponent(0.3)
        shadow.shadowOffset = CGSize(width: 0, height: 0)
        shadow.shadowBlurRadius = 1
        
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 10.63, y: 15.47))
        bezierPath.addLine(to: CGPoint(x: 17.18, y: 8.92))
        bezierPath.addLine(to: CGPoint(x: 16.5, y: 8.24))
        bezierPath.addLine(to: CGPoint(x: 10.15, y: 14.6))
        bezierPath.addLine(to: CGPoint(x: 7.45, y: 11.9))
        bezierPath.addLine(to: CGPoint(x: 6.78, y: 12.57))
        bezierPath.addLine(to: CGPoint(x: 10.15, y: 15.95))
        bezierPath.addLine(to: CGPoint(x: 10.63, y: 15.47))
        bezierPath.close()
        bezierPath.move(to: CGPoint(x: 11.5, y: 22))
        bezierPath.addCurve(to: CGPoint(x: 22, y: 11.5), controlPoint1: CGPoint(x: 17.3, y: 22), controlPoint2: CGPoint(x: 22, y: 17.3))
        bezierPath.addCurve(to: CGPoint(x: 11.5, y: 1), controlPoint1: CGPoint(x: 22, y: 5.7), controlPoint2: CGPoint(x: 17.3, y: 1))
        bezierPath.addCurve(to: CGPoint(x: 1, y: 11.5), controlPoint1: CGPoint(x: 5.7, y: 1), controlPoint2: CGPoint(x: 1, y: 5.7))
        bezierPath.addCurve(to: CGPoint(x: 11.5, y: 22), controlPoint1: CGPoint(x: 1, y: 17.3), controlPoint2: CGPoint(x: 5.7, y: 22))
        bezierPath.close()
        bezierPath.usesEvenOddFillRule = true
        
        context!.saveGState()
        context!.setShadow(offset: shadow.shadowOffset, blur: shadow.shadowBlurRadius, color: (shadow.shadowColor as! UIColor).cgColor)
        self.color.setFill()
        bezierPath.fill()
        context!.restoreGState()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 23, height: 23)
    }
 
}
