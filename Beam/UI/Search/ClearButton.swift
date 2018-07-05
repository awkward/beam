//
//  ClearButton.swift
//  beam
//
//  Created by Robin Speijer on 15-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

private class ClearIconView: UIView {
    
    var foregroundColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
    
    fileprivate override func draw(_ rect: CGRect) {
        
        //// X Drawing
        let xPath = UIBezierPath()
        xPath.move(to: CGPoint(x: rect.minX + 0.63864 * rect.width, y: rect.minY + 0.50606 * rect.height))
        xPath.addLine(to: CGPoint(x: rect.minX + 0.85938 * rect.width, y: rect.minY + 0.28532 * rect.height))
        xPath.addCurve(to: CGPoint(x: rect.minX + 0.85961 * rect.width, y: rect.minY + 0.15250 * rect.height), controlPoint1: CGPoint(x: rect.minX + 0.89642 * rect.width, y: rect.minY + 0.24828 * rect.height), controlPoint2: CGPoint(x: rect.minX + 0.89622 * rect.width, y: rect.minY + 0.18912 * rect.height))
        xPath.addCurve(to: CGPoint(x: rect.minX + 0.72680 * rect.width, y: rect.minY + 0.15274 * rect.height), controlPoint1: CGPoint(x: rect.minX + 0.82274 * rect.width, y: rect.minY + 0.11564 * rect.height), controlPoint2: CGPoint(x: rect.minX + 0.76354 * rect.width, y: rect.minY + 0.11600 * rect.height))
        xPath.addLine(to: CGPoint(x: rect.minX + 0.50606 * rect.width, y: rect.minY + 0.37347 * rect.height))
        xPath.addLine(to: CGPoint(x: rect.minX + 0.28532 * rect.width, y: rect.minY + 0.15274 * rect.height))
        xPath.addCurve(to: CGPoint(x: rect.minX + 0.15250 * rect.width, y: rect.minY + 0.15250 * rect.height), controlPoint1: CGPoint(x: rect.minX + 0.24828 * rect.width, y: rect.minY + 0.11570 * rect.height), controlPoint2: CGPoint(x: rect.minX + 0.18912 * rect.width, y: rect.minY + 0.11589 * rect.height))
        xPath.addCurve(to: CGPoint(x: rect.minX + 0.15274 * rect.width, y: rect.minY + 0.28532 * rect.height), controlPoint1: CGPoint(x: rect.minX + 0.11564 * rect.width, y: rect.minY + 0.18937 * rect.height), controlPoint2: CGPoint(x: rect.minX + 0.11600 * rect.width, y: rect.minY + 0.24858 * rect.height))
        xPath.addLine(to: CGPoint(x: rect.minX + 0.37347 * rect.width, y: rect.minY + 0.50606 * rect.height))
        xPath.addLine(to: CGPoint(x: rect.minX + 0.15274 * rect.width, y: rect.minY + 0.72680 * rect.height))
        xPath.addCurve(to: CGPoint(x: rect.minX + 0.15250 * rect.width, y: rect.minY + 0.85961 * rect.height), controlPoint1: CGPoint(x: rect.minX + 0.11570 * rect.width, y: rect.minY + 0.76384 * rect.height), controlPoint2: CGPoint(x: rect.minX + 0.11589 * rect.width, y: rect.minY + 0.82300 * rect.height))
        xPath.addCurve(to: CGPoint(x: rect.minX + 0.28532 * rect.width, y: rect.minY + 0.85938 * rect.height), controlPoint1: CGPoint(x: rect.minX + 0.18937 * rect.width, y: rect.minY + 0.89648 * rect.height), controlPoint2: CGPoint(x: rect.minX + 0.24858 * rect.width, y: rect.minY + 0.89612 * rect.height))
        xPath.addLine(to: CGPoint(x: rect.minX + 0.50606 * rect.width, y: rect.minY + 0.63864 * rect.height))
        xPath.addLine(to: CGPoint(x: rect.minX + 0.72680 * rect.width, y: rect.minY + 0.85938 * rect.height))
        xPath.addCurve(to: CGPoint(x: rect.minX + 0.85961 * rect.width, y: rect.minY + 0.85961 * rect.height), controlPoint1: CGPoint(x: rect.minX + 0.76384 * rect.width, y: rect.minY + 0.89642 * rect.height), controlPoint2: CGPoint(x: rect.minX + 0.82300 * rect.width, y: rect.minY + 0.89622 * rect.height))
        xPath.addCurve(to: CGPoint(x: rect.minX + 0.85938 * rect.width, y: rect.minY + 0.72680 * rect.height), controlPoint1: CGPoint(x: rect.minX + 0.89648 * rect.width, y: rect.minY + 0.82274 * rect.height), controlPoint2: CGPoint(x: rect.minX + 0.89612 * rect.width, y: rect.minY + 0.76354 * rect.height))
        xPath.addLine(to: CGPoint(x: rect.minX + 0.63864 * rect.width, y: rect.minY + 0.50606 * rect.height))
        xPath.addLine(to: CGPoint(x: rect.minX + 0.63864 * rect.width, y: rect.minY + 0.50606 * rect.height))
        xPath.close()
        xPath.miterLimit = 4
        
        xPath.usesEvenOddFillRule = true
        
        foregroundColor.setFill()
        xPath.fill()
        
    }
    
    fileprivate override var intrinsicContentSize: CGSize {
        return CGSize(width: 8, height: 8)
    }
    
}

class ClearButton: UIControl {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    var clearHandler: (() -> Void)?
    var foregroundColor: UIColor {
        get {
            return xView.foregroundColor
        }
        set {
            xView.foregroundColor = newValue
            clearLabel.textColor = newValue
        }
    }
    
    fileprivate var xView = ClearIconView(frame: CGRect(x: 4, y: 4, width: 8, height: 8))
    fileprivate var clearLabel = UILabel(frame: CGRect.zero)
    fileprivate var widthConstraint: NSLayoutConstraint!
    
    fileprivate func setupView() {
        
        backgroundColor = UIColor.beamGreyLighter()
        
        widthConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: CGFloat(1.0), constant: CGFloat(16.0))
        addConstraint(widthConstraint)
        
        clearLabel.backgroundColor = UIColor.clear
        clearLabel.translatesAutoresizingMaskIntoConstraints = false
        clearLabel.text = NSLocalizedString("clear", comment: "Clear").uppercased(with: Locale.current)
        clearLabel.font = UIFont.systemFont(ofSize: 10)
        clearLabel.textAlignment = NSTextAlignment.center
        clearLabel.lineBreakMode = NSLineBreakMode.byCharWrapping
        clearLabel.textColor = UIColor.white
        clearLabel.alpha = 0
        clearLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 0), for: UILayoutConstraintAxis.horizontal)
        clearLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 0), for: UILayoutConstraintAxis.vertical)
        
        addSubview(clearLabel)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|", options: [], metrics: nil, views: ["label": clearLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[label]|", options: [], metrics: nil, views: ["label": clearLabel]))
        
        xView.backgroundColor = UIColor.clear
        xView.isUserInteractionEnabled = false
        xView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(xView)
        addConstraint(NSLayoutConstraint(item: xView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: xView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        
        addTarget(self, action: #selector(ClearButton.buttonTapped(_:)), for: UIControlEvents.touchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 0.5 * frame.height
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 16, height: 16)
    }
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            super.isSelected = newValue
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { () -> Void in
                self.xView.transform = CGAffineTransform(rotationAngle: newValue ? -0.5 * CGFloat.pi: 0)
                self.xView.alpha = newValue ? 0: 1
                self.clearLabel.alpha = newValue ? 1: 0
                self.widthConstraint.constant = newValue ? self.clearLabel.intrinsicContentSize.width + 10: 16
                self.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    @objc fileprivate func buttonTapped(_ sender: AnyObject) {
        if isSelected {
            clearHandler?()
        }
        
        isSelected = !isSelected
    }
    
    override func resignFirstResponder() -> Bool {
        isSelected = false
        
        return super.resignFirstResponder()
    }

}
