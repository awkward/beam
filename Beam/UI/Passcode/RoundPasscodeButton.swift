//
//  RoundPasscodeButton.swift
//  Beam
//
//  Created by Rens Verhoeven on 25-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit

@IBDesignable
class RoundPasscodeButton: PasscodeButton {
    
    override var number: Int {
        didSet {
            self.updateImages()
        }
    }
    
    fileprivate func updateImages() {
        self.normalImage = self.buttonImage(false)
        self.highlightedImage = self.buttonImage(true)
        self.updateStateImage()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateImages()
    }
    
    fileprivate var normalImage: UIImage?
    fileprivate var highlightedImage: UIImage?
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.updateImages()
    }
    
    fileprivate func buttonImage(_ inverted: Bool) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 76, height: 76)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        
        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        let strokeColor = self.tintColor
        let textColor: UIColor = self.tintColor ?? UIColor.white
        
        let strokeWidth: CGFloat = 2
        let path = UIBezierPath(ovalIn: rect.insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2))
        path.lineWidth = strokeWidth
        strokeColor?.setStroke()
        path.stroke()
        
        if inverted == true {
            strokeColor?.setFill()
            path.fill()
        }
        
        let numbersFont = UIFont.systemFont(ofSize: 36, weight: UIFont.Weight.thin)
        let lettersFont = UIFont.systemFont(ofSize: 9, weight: UIFont.Weight.light)
        let numbersToLettersSpacing: CGFloat = -5
        let numbersAndLettersHeight = numbersFont.lineHeight + lettersFont.lineHeight + numbersToLettersSpacing
        
        var yPosition = ((rect.height - numbersAndLettersHeight) / 2) - 3
        
        let numberTextAttributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: numbersFont]
        let numberTextSize = self.numberString.boundingRect(with: rect.size, options: NSStringDrawingOptions.usesFontLeading, attributes: numberTextAttributes, context: nil).size
        var numberTextRect = CGRect(origin: CGPoint(x: (rect.width - numberTextSize.width) / 2, y: yPosition), size: numberTextSize)
        
        numberTextRect.origin.x = round(numberTextRect.origin.x)
        numberTextRect.origin.y = round(numberTextRect.origin.y)
        numberTextRect.size.width = round(numberTextRect.size.width)
        numberTextRect.size.height = round(numberTextRect.size.height)
        
        yPosition += numbersFont.lineHeight
        yPosition += numbersToLettersSpacing
        
        if inverted == true {
            context.setBlendMode(CGBlendMode.sourceOut)
        }
        self.numberString.draw(in: numberTextRect, withAttributes: numberTextAttributes)
    
        if let lettersString = self.lettersString?.uppercased {
            let lettersTextAttributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: lettersFont]
            let lettersTextSize = lettersString.boundingRect(with: rect.size, options: NSStringDrawingOptions.usesFontLeading, attributes: lettersTextAttributes, context: nil).size
            let lettersTextRect = CGRect(origin: CGPoint(x: (rect.width - lettersTextSize.width) / 2, y: yPosition), size: lettersTextSize)
            
            if inverted == true {
                context.setBlendMode(CGBlendMode.sourceOut)
            }
            lettersString.draw(in: lettersTextRect, withAttributes: lettersTextAttributes)
        }
        
        let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    override var isHighlighted: Bool {
        didSet {
            if oldValue == false && self.isHighlighted == true {
                self.updateStateImage()
            } else if oldValue == true && self.isHighlighted == false {
                self.updateStateImage(true)
            }
        }
    }
    
    func updateStateImage(_ animated: Bool = false) {
        var duration = 0.32
        if animated == false {
            duration = 0
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        self.layer.contents = self.isHighlighted ? self.highlightedImage?.cgImage: self.normalImage?.cgImage
        CATransaction.commit()
    }
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if event == "contents" {
            return nil
        }
        return super.action(for: layer, forKey: event)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 74, height: 74)
    }

}
