//
//  PasscodeKeyboard.swift
//  Beam
//
//  Created by Rens Verhoeven on 08-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

protocol PasscodeKeyboardDelegate: class {
    
    func keyboard(_ keyboard: PasscodeKeyboard, didPressNumber number: Int)
    func keyboard(_ keyboard: PasscodeKeyboard, didPressDelete deleteButton: DeleteButton)
}

class DeleteButton: UIControl {
    
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
    
    fileprivate func adjustBackgroundColor() {
        if self.isHighlighted {
            self.backgroundColor = self.highlightedBackgroundColor
        } else {
            self.backgroundColor = self.normalBackgroundColor
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = self.isHighlighted ? self.highlightedBackgroundColor: self.normalBackgroundColor
            self.setNeedsDisplay()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let iconSize = CGSize(width: 23, height: 17)
        let iconOrigin = CGPoint(x: (rect.width - iconSize.width) / 2, y: (rect.height - iconSize.height) / 2)
        let iconRect = CGRect(origin: iconOrigin, size: iconSize)
        if self.isHighlighted {
            self.drawDeleteIconFilled(frame: iconRect, color: self.tintColor)
        } else {
            self.drawDeleteIcon(frame: iconRect, color: self.tintColor)
        }
    }

    fileprivate func drawDeleteIconFilled(frame: CGRect = CGRect(x: 0, y: 0, width: 23, height: 17), color: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {
        
        //// Bezier Drawing
        let bezierPath: UIBezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: frame.minX + 13.5, y: frame.minY + 7.44))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 11.03, y: frame.minY + 4.97))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 9.96, y: frame.minY + 4.96), controlPoint1: CGPoint(x: frame.minX + 10.73, y: frame.minY + 4.67), controlPoint2: CGPoint(x: frame.minX + 10.26, y: frame.minY + 4.67))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 9.97, y: frame.minY + 6.03), controlPoint1: CGPoint(x: frame.minX + 9.67, y: frame.minY + 5.26), controlPoint2: CGPoint(x: frame.minX + 9.67, y: frame.minY + 5.73))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 12.44, y: frame.minY + 8.5))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 9.97, y: frame.minY + 10.97))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 9.96, y: frame.minY + 12.04), controlPoint1: CGPoint(x: frame.minX + 9.67, y: frame.minY + 11.27), controlPoint2: CGPoint(x: frame.minX + 9.67, y: frame.minY + 11.74))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 11.03, y: frame.minY + 12.03), controlPoint1: CGPoint(x: frame.minX + 10.26, y: frame.minY + 12.33), controlPoint2: CGPoint(x: frame.minX + 10.73, y: frame.minY + 12.33))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 13.5, y: frame.minY + 9.56))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 15.97, y: frame.minY + 12.03))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 17.04, y: frame.minY + 12.04), controlPoint1: CGPoint(x: frame.minX + 16.27, y: frame.minY + 12.33), controlPoint2: CGPoint(x: frame.minX + 16.74, y: frame.minY + 12.33))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 17.03, y: frame.minY + 10.97), controlPoint1: CGPoint(x: frame.minX + 17.33, y: frame.minY + 11.74), controlPoint2: CGPoint(x: frame.minX + 17.33, y: frame.minY + 11.27))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 14.56, y: frame.minY + 8.5))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 17.03, y: frame.minY + 6.03))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 17.04, y: frame.minY + 4.96), controlPoint1: CGPoint(x: frame.minX + 17.33, y: frame.minY + 5.73), controlPoint2: CGPoint(x: frame.minX + 17.33, y: frame.minY + 5.26))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 15.97, y: frame.minY + 4.97), controlPoint1: CGPoint(x: frame.minX + 16.74, y: frame.minY + 4.67), controlPoint2: CGPoint(x: frame.minX + 16.27, y: frame.minY + 4.67))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 13.5, y: frame.minY + 7.44))
        bezierPath.close()
        bezierPath.move(to: CGPoint(x: frame.minX + 0.25, y: frame.minY + 8.5))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 3.46, y: frame.minY + 4.3), controlPoint1: CGPoint(x: frame.minX + 0.25, y: frame.minY + 7.49), controlPoint2: CGPoint(x: frame.minX + 1.01, y: frame.minY + 6.64))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 3.85, y: frame.minY + 3.93), controlPoint1: CGPoint(x: frame.minX + 3.59, y: frame.minY + 4.18), controlPoint2: CGPoint(x: frame.minX + 3.72, y: frame.minY + 4.06))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 6.02, y: frame.minY + 1.92), controlPoint1: CGPoint(x: frame.minX + 4.54, y: frame.minY + 3.27), controlPoint2: CGPoint(x: frame.minX + 5.28, y: frame.minY + 2.59))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 6.74, y: frame.minY + 1.28), controlPoint1: CGPoint(x: frame.minX + 6.28, y: frame.minY + 1.69), controlPoint2: CGPoint(x: frame.minX + 6.52, y: frame.minY + 1.47))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 7.01, y: frame.minY + 1.04), controlPoint1: CGPoint(x: frame.minX + 6.87, y: frame.minY + 1.16), controlPoint2: CGPoint(x: frame.minX + 6.97, y: frame.minY + 1.08))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 9.75, y: frame.minY), controlPoint1: CGPoint(x: frame.minX + 7.7, y: frame.minY + 0.43), controlPoint2: CGPoint(x: frame.minX + 8.83, y: frame.minY))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 19.25, y: frame.minY))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 22.75, y: frame.minY + 3.5), controlPoint1: CGPoint(x: frame.minX + 21.18, y: frame.minY), controlPoint2: CGPoint(x: frame.minX + 22.75, y: frame.minY + 1.57))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 22.75, y: frame.minY + 13.5))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 19.25, y: frame.minY + 17), controlPoint1: CGPoint(x: frame.minX + 22.75, y: frame.minY + 15.43), controlPoint2: CGPoint(x: frame.minX + 21.18, y: frame.minY + 17))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 9.75, y: frame.minY + 17))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 7.01, y: frame.minY + 15.96), controlPoint1: CGPoint(x: frame.minX + 8.83, y: frame.minY + 17), controlPoint2: CGPoint(x: frame.minX + 7.69, y: frame.minY + 16.56))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 6.73, y: frame.minY + 15.71), controlPoint1: CGPoint(x: frame.minX + 6.96, y: frame.minY + 15.91), controlPoint2: CGPoint(x: frame.minX + 6.87, y: frame.minY + 15.83))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 6.02, y: frame.minY + 15.07), controlPoint1: CGPoint(x: frame.minX + 6.52, y: frame.minY + 15.52), controlPoint2: CGPoint(x: frame.minX + 6.28, y: frame.minY + 15.31))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 3.84, y: frame.minY + 13.07), controlPoint1: CGPoint(x: frame.minX + 5.28, y: frame.minY + 14.4), controlPoint2: CGPoint(x: frame.minX + 4.54, y: frame.minY + 13.72))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 3.46, y: frame.minY + 12.7), controlPoint1: CGPoint(x: frame.minX + 3.71, y: frame.minY + 12.94), controlPoint2: CGPoint(x: frame.minX + 3.58, y: frame.minY + 12.82))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.25, y: frame.minY + 8.5), controlPoint1: CGPoint(x: frame.minX + 1.01, y: frame.minY + 10.35), controlPoint2: CGPoint(x: frame.minX + 0.25, y: frame.minY + 9.51))
        bezierPath.close()
        color.setFill()
        bezierPath.fill()
    }

    fileprivate func drawDeleteIcon(frame: CGRect = CGRect(x: 0, y: 103, width: 23, height: 17), color: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {
        
        //// Bezier Drawing
        let bezierPath: UIBezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: frame.minX + 1.75, y: frame.minY + 8.5))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 1.75, y: frame.minY + 8.5))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 8, y: frame.minY + 14.83), controlPoint1: CGPoint(x: frame.minX + 1.75, y: frame.minY + 9.33), controlPoint2: CGPoint(x: frame.minX + 8, y: frame.minY + 14.83))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 9.75, y: frame.minY + 15.5), controlPoint1: CGPoint(x: frame.minX + 8.41, y: frame.minY + 15.2), controlPoint2: CGPoint(x: frame.minX + 9.2, y: frame.minY + 15.5))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 19.25, y: frame.minY + 15.5))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 21.25, y: frame.minY + 13.5), controlPoint1: CGPoint(x: frame.minX + 20.35, y: frame.minY + 15.5), controlPoint2: CGPoint(x: frame.minX + 21.25, y: frame.minY + 14.61))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 21.25, y: frame.minY + 3.5))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 19.25, y: frame.minY + 1.5), controlPoint1: CGPoint(x: frame.minX + 21.25, y: frame.minY + 2.4), controlPoint2: CGPoint(x: frame.minX + 20.35, y: frame.minY + 1.5))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 9.75, y: frame.minY + 1.5))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 8.01, y: frame.minY + 2.16), controlPoint1: CGPoint(x: frame.minX + 9.19, y: frame.minY + 1.5), controlPoint2: CGPoint(x: frame.minX + 8.42, y: frame.minY + 1.8))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 1.75, y: frame.minY + 8.5), controlPoint1: CGPoint(x: frame.minX + 8.01, y: frame.minY + 2.16), controlPoint2: CGPoint(x: frame.minX + 1.75, y: frame.minY + 7.67))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 1.75, y: frame.minY + 8.5))
        bezierPath.close()
        bezierPath.move(to: CGPoint(x: frame.minX + 13.5, y: frame.minY + 7.44))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 11.03, y: frame.minY + 4.97))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 9.96, y: frame.minY + 4.96), controlPoint1: CGPoint(x: frame.minX + 10.73, y: frame.minY + 4.67), controlPoint2: CGPoint(x: frame.minX + 10.26, y: frame.minY + 4.67))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 9.97, y: frame.minY + 6.03), controlPoint1: CGPoint(x: frame.minX + 9.67, y: frame.minY + 5.26), controlPoint2: CGPoint(x: frame.minX + 9.67, y: frame.minY + 5.73))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 12.44, y: frame.minY + 8.5))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 9.97, y: frame.minY + 10.97))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 9.96, y: frame.minY + 12.04), controlPoint1: CGPoint(x: frame.minX + 9.67, y: frame.minY + 11.27), controlPoint2: CGPoint(x: frame.minX + 9.67, y: frame.minY + 11.74))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 11.03, y: frame.minY + 12.03), controlPoint1: CGPoint(x: frame.minX + 10.26, y: frame.minY + 12.33), controlPoint2: CGPoint(x: frame.minX + 10.73, y: frame.minY + 12.33))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 13.5, y: frame.minY + 9.56))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 15.97, y: frame.minY + 12.03))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 17.04, y: frame.minY + 12.04), controlPoint1: CGPoint(x: frame.minX + 16.27, y: frame.minY + 12.33), controlPoint2: CGPoint(x: frame.minX + 16.74, y: frame.minY + 12.33))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 17.03, y: frame.minY + 10.97), controlPoint1: CGPoint(x: frame.minX + 17.33, y: frame.minY + 11.74), controlPoint2: CGPoint(x: frame.minX + 17.33, y: frame.minY + 11.27))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 14.56, y: frame.minY + 8.5))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 17.03, y: frame.minY + 6.03))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 17.04, y: frame.minY + 4.96), controlPoint1: CGPoint(x: frame.minX + 17.33, y: frame.minY + 5.73), controlPoint2: CGPoint(x: frame.minX + 17.33, y: frame.minY + 5.26))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 15.97, y: frame.minY + 4.97), controlPoint1: CGPoint(x: frame.minX + 16.74, y: frame.minY + 4.67), controlPoint2: CGPoint(x: frame.minX + 16.27, y: frame.minY + 4.67))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 13.5, y: frame.minY + 7.44))
        bezierPath.close()
        bezierPath.move(to: CGPoint(x: frame.minX + 0.25, y: frame.minY + 8.5))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 3.46, y: frame.minY + 4.3), controlPoint1: CGPoint(x: frame.minX + 0.25, y: frame.minY + 7.49), controlPoint2: CGPoint(x: frame.minX + 1.01, y: frame.minY + 6.64))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 3.85, y: frame.minY + 3.93), controlPoint1: CGPoint(x: frame.minX + 3.59, y: frame.minY + 4.18), controlPoint2: CGPoint(x: frame.minX + 3.72, y: frame.minY + 4.06))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 6.02, y: frame.minY + 1.92), controlPoint1: CGPoint(x: frame.minX + 4.54, y: frame.minY + 3.27), controlPoint2: CGPoint(x: frame.minX + 5.28, y: frame.minY + 2.59))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 6.74, y: frame.minY + 1.28), controlPoint1: CGPoint(x: frame.minX + 6.28, y: frame.minY + 1.69), controlPoint2: CGPoint(x: frame.minX + 6.52, y: frame.minY + 1.47))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 7.01, y: frame.minY + 1.04), controlPoint1: CGPoint(x: frame.minX + 6.87, y: frame.minY + 1.16), controlPoint2: CGPoint(x: frame.minX + 6.97, y: frame.minY + 1.08))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 9.75, y: frame.minY), controlPoint1: CGPoint(x: frame.minX + 7.7, y: frame.minY + 0.43), controlPoint2: CGPoint(x: frame.minX + 8.83, y: frame.minY))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 19.25, y: frame.minY))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 22.75, y: frame.minY + 3.5), controlPoint1: CGPoint(x: frame.minX + 21.18, y: frame.minY), controlPoint2: CGPoint(x: frame.minX + 22.75, y: frame.minY + 1.57))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 22.75, y: frame.minY + 13.5))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 19.25, y: frame.minY + 17), controlPoint1: CGPoint(x: frame.minX + 22.75, y: frame.minY + 15.43), controlPoint2: CGPoint(x: frame.minX + 21.18, y: frame.minY + 17))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 9.75, y: frame.minY + 17))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 7.01, y: frame.minY + 15.96), controlPoint1: CGPoint(x: frame.minX + 8.83, y: frame.minY + 17), controlPoint2: CGPoint(x: frame.minX + 7.69, y: frame.minY + 16.56))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 6.73, y: frame.minY + 15.71), controlPoint1: CGPoint(x: frame.minX + 6.96, y: frame.minY + 15.91), controlPoint2: CGPoint(x: frame.minX + 6.87, y: frame.minY + 15.83))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 6.02, y: frame.minY + 15.07), controlPoint1: CGPoint(x: frame.minX + 6.52, y: frame.minY + 15.52), controlPoint2: CGPoint(x: frame.minX + 6.28, y: frame.minY + 15.31))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 3.84, y: frame.minY + 13.07), controlPoint1: CGPoint(x: frame.minX + 5.28, y: frame.minY + 14.4), controlPoint2: CGPoint(x: frame.minX + 4.54, y: frame.minY + 13.72))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 3.46, y: frame.minY + 12.7), controlPoint1: CGPoint(x: frame.minX + 3.71, y: frame.minY + 12.94), controlPoint2: CGPoint(x: frame.minX + 3.58, y: frame.minY + 12.82))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.25, y: frame.minY + 8.5), controlPoint1: CGPoint(x: frame.minX + 1.01, y: frame.minY + 10.35), controlPoint2: CGPoint(x: frame.minX + 0.25, y: frame.minY + 9.51))
        bezierPath.close()
        color.setFill()
        bezierPath.fill()
    }
}

@IBDesignable
class PasscodeKeyboard: UIView {
    
    weak var delegate: PasscodeKeyboardDelegate?
    
    var appearance = UIKeyboardAppearance.default {
        didSet {
            self.configureColors()
        }
    }
    
    fileprivate var allViews: [UIView]!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    fileprivate func setupView() {
        
        let spacing: CGFloat = 1.0 / UIScreen.main.scale
        
        var number: Int = 1
        var stackViews: [UIStackView] = [UIStackView]()
        var allViews: [UIView] = [UIView]()
        for row: Int in 0...3 {
            var views = [UIView]()
            if row == 3 {
                //Last row, do something special!
                
                //Add an empty view where the dot is supposed to be
                let emptyView: UIView = UIView()
                views.append(emptyView)
                allViews.append(emptyView)
                
                //Add the zero passcode button
                let button: PasscodeButton = PasscodeButton(number: 0)
                button.addTarget(self, action: #selector(PasscodeKeyboard.buttonTapped(_:)), for: UIControlEvents.touchUpInside)
                views.append(button)
                allViews.append(button)
                
                let deleteButton: DeleteButton = DeleteButton(frame: CGRect.zero)
                deleteButton.addTarget(self, action: #selector(PasscodeKeyboard.buttonTapped(_:)), for: UIControlEvents.touchUpInside)
                views.append(deleteButton)
                allViews.append(deleteButton)
            } else {
                for _ in 0...2 {
                    let button = PasscodeButton(number: number)
                    button.addTarget(self, action: #selector(PasscodeKeyboard.buttonTapped(_:)), for: UIControlEvents.touchUpInside)
                    views.append(button)
                    allViews.append(button)
                    number += 1
                }
            }
            
            let stackView: UIStackView = UIStackView(arrangedSubviews: views)
            stackView.spacing = spacing
            stackView.alignment = UIStackViewAlignment.fill
            stackView.distribution = UIStackViewDistribution.fillEqually
            stackView.axis = UILayoutConstraintAxis.horizontal
            stackViews.append(stackView)
        }
        
        self.allViews = allViews
        
        let verticalStackView: UIStackView = UIStackView(arrangedSubviews: stackViews)
        verticalStackView.spacing = spacing
        verticalStackView.alignment = UIStackViewAlignment.fill
        verticalStackView.distribution = UIStackViewDistribution.fillEqually
        verticalStackView.axis = UILayoutConstraintAxis.vertical
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.configureColors()
        
        self.addSubview(verticalStackView)
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: verticalStackView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
    }
    
    @objc fileprivate func buttonTapped(_ sender: UIControl) {
        if let passcodeButton = sender as? PasscodeButton {
            self.delegate?.keyboard(self, didPressNumber: passcodeButton.number)
        } else if let deleteButton = sender as? DeleteButton {
            self.delegate?.keyboard(self, didPressDelete: deleteButton)
        }
    }
    
    fileprivate func configureColors() {
        var backgroundColor = UIColor(red: 0.55, green: 0.55, blue: 0.56, alpha: 1.00)
        var textColor = UIColor.black
        var buttonBackgroundColor = UIColor.white
        var sideButtonsBackgroundColor = UIColor(red: 0.81, green: 0.82, blue: 0.85, alpha: 1.00)
        
        if self.appearance == UIKeyboardAppearance.dark {
            backgroundColor = UIColor(red: 0.31, green: 0.31, blue: 0.31, alpha: 1.00)
            textColor = UIColor.white
            buttonBackgroundColor = UIColor(red: 0.54, green: 0.54, blue: 0.54, alpha: 1.00)
            sideButtonsBackgroundColor = UIColor(red: 0.30, green: 0.31, blue: 0.32, alpha: 1.00)
        }
        
        self.backgroundColor = backgroundColor
        
        for view in self.allViews {
            if let passcodeButton = view as? PasscodeButton {
                passcodeButton.normalBackgroundColor = buttonBackgroundColor
                passcodeButton.highlightedBackgroundColor = sideButtonsBackgroundColor
                passcodeButton.textColor = textColor
                passcodeButton.backgroundColor = buttonBackgroundColor
            } else if let button = view as? DeleteButton {
                if button.tintColor != textColor {
                    button.tintColor = textColor
                }
                button.normalBackgroundColor = sideButtonsBackgroundColor
                button.highlightedBackgroundColor = buttonBackgroundColor
                button.isOpaque = true
                button.backgroundColor = sideButtonsBackgroundColor
            } else {
                view.isOpaque = true
                view.backgroundColor = sideButtonsBackgroundColor
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 320, height: 217)
    }

}
