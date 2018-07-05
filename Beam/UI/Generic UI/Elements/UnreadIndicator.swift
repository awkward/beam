//
//  UnreadIndicator.swift
//  beam
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

@IBDesignable class UnreadIndicator: UIView {
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 10, height: 10)
    }

    override func draw(_ rect: CGRect) {
        let stroke = self.tintColor
        
        var strokeHueComponent: CGFloat = 1,
        strokeSaturationComponent: CGFloat = 1,
        strokeBrightnessComponent: CGFloat = 1
        stroke?.getHue(&strokeHueComponent, saturation: &strokeSaturationComponent, brightness: &strokeBrightnessComponent, alpha: nil)
        
        let fill = UIColor(hue: strokeHueComponent, saturation: 0.933 * strokeSaturationComponent, brightness: strokeBrightnessComponent, alpha: (stroke?.cgColor.alpha)!)
        
        //// indicator Drawing
        let indicatorPath = UIBezierPath(ovalIn: CGRect(x: rect.minX + 1, y: rect.minY + 1, width: rect.width - 2, height: rect.height - 2))
        fill.setFill()
        indicatorPath.fill()
        stroke?.setStroke()
        indicatorPath.lineWidth = 1
        indicatorPath.stroke()
    }

}
