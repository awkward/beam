//
//  PasscodeButton.swift
//  Beam
//
//  Created by Rens Verhoeven on 08-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

@IBDesignable
class PasscodeButton: UIControl {
    
    var normalBackgroundColor = UIColor.white {
        didSet {
            self.adjustBackgroundColor()
        }
    }
    
    var highlightedBackgroundColor = UIColor.black {
        didSet {
            self.adjustBackgroundColor()
        }
    }
    
    var textColor = UIColor.black {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    init(number: Int) {
        super.init(frame: CGRect.zero)
        self.number = number
        self.setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }

    @IBInspectable var number: Int = 0
    
    fileprivate func setupView() {
        self.backgroundColor = UIColor.white
        self.isOpaque = true
    }
    
    internal var numberString: NSString {
        return "\(self.number)" as NSString
    }
    
    internal var lettersString: NSString? {
        switch self.number {
        case 2:
            return "a b c"
        case 3:
            return "d e f"
        case 4:
            return "g h i"
        case 5:
            return "j k l"
        case 6:
            return "m n o"
        case 7:
            return "p q r s"
        case 8:
            return "t u v"
        case 9:
            return "w x y z"
        default:
            return nil
        }
    }
    
    override func draw(_ rect: CGRect) {
        let textColor = self.textColor
        
        let numbersFont = UIFont.systemFont(ofSize: 29, weight: UIFont.Weight.regular)
        let lettersFont = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.regular)
        let numbersToLettersSpacing: CGFloat = -2
        let numbersAndLettersHeight = numbersFont.lineHeight + lettersFont.lineHeight + numbersToLettersSpacing
        
        var yPosition = ((rect.height - numbersAndLettersHeight) / 2)
        
        let numberTextAttributes = [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: numbersFont]
        let numberTextSize = self.numberString.boundingRect(with: rect.size, options: NSStringDrawingOptions.usesFontLeading, attributes: numberTextAttributes, context: nil).size
        var numberTextRect = CGRect(origin: CGPoint(x: (rect.width - numberTextSize.width) / 2, y: yPosition), size: numberTextSize)
        if self.number == 0 {
            numberTextRect.origin.y = (rect.height - numbersFont.lineHeight) / 2
        }
        
        yPosition += numbersFont.lineHeight
        yPosition += numbersToLettersSpacing
        
        self.numberString.draw(in: numberTextRect, withAttributes: numberTextAttributes)
        
        if let lettersString = self.lettersString?.replacingOccurrences(of: " ", with: "").uppercased() {
            let lettersTextAttributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: lettersFont, NSAttributedStringKey.kern: 1.1]
            let lettersTextSize = lettersString.boundingRect(with: rect.size, options: NSStringDrawingOptions.usesFontLeading, attributes: lettersTextAttributes, context: nil).size
            let lettersTextRect = CGRect(origin: CGPoint(x: (rect.width - lettersTextSize.width) / 2, y: yPosition), size: lettersTextSize)
            
            lettersString.draw(in: lettersTextRect, withAttributes: lettersTextAttributes)
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.adjustBackgroundColor()
        }
    }
    
    internal func adjustBackgroundColor() {
        if self.isHighlighted {
            self.backgroundColor = self.highlightedBackgroundColor
        } else {
            self.backgroundColor = self.normalBackgroundColor
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 80, height: 53.5)
    }
 
}
