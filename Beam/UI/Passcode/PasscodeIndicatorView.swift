//
//  PasscodeIndicatorView.swift
//  Beam
//
//  Created by Rens Verhoeven on 11-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

@IBDesignable
class PasscodeIndicatorView: UIView {

    @IBInspectable var filled: Bool = false {
        didSet {
            if self.filled == false && oldValue == true {
                self.updateStateImage(true)
            } else {
                self.updateStateImage()
            }
            
        }
    }
    
    fileprivate var normalImage: UIImage?
    fileprivate var filledImage: UIImage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.updateImages()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.updateImages()
    }
    
    fileprivate func updateImages() {
        #if TARGET_INTERFACE_BUILDER
            return
        #endif
        self.normalImage = self.buttonImage(false)
        self.filledImage = self.buttonImage(true)
        
        self.updateStateImage()
    }
    
    override func layoutSubviews() {
       super.layoutSubviews()
        self.updateImages()
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.updateImages()
    }
    
    fileprivate func buttonImage(_ filled: Bool) -> UIImage? {
        let rect = self.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        
        if filled {
            self.drawPasscodeIndicatorFilled(frame: rect, color: self.tintColor)
        } else {
            self.drawPasscodeIndicator(frame: rect, color: self.tintColor)
        }
        
        let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func drawPasscodeIndicator(lineWidth: CGFloat = 1, frame: CGRect = CGRect(x: 0, y: 0, width: 15, height: 15), color: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {
        let offset = lineWidth / 2
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: frame.minX + offset, y: frame.minY + offset, width: frame.width - lineWidth, height: frame.height - lineWidth))
        ovalPath.lineWidth = lineWidth

        color.setStroke()
        ovalPath.stroke()
    }
    
    func drawPasscodeIndicatorFilled(frame: CGRect = CGRect(x: 0, y: 0, width: 15, height: 15), color: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {
        
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height))
        color.setFill()
        ovalPath.fill()
    }

    func updateStateImage(_ animated: Bool = false) {
        var duration = 0.32
        if animated == false {
            duration = 0
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        self.layer.contents = self.filled ? self.filledImage?.cgImage: self.normalImage?.cgImage
        CATransaction.commit()
    }
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if event == "contents" {
            return nil
        }
        return super.action(for: layer, forKey: event)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 15, height: 15)
    }

}
