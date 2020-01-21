//
//  ButtonBar.swift
//  beam
//
//  Created by Robin Speijer on 02-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class ButtonBar: UIControl {
    
    class Button: Equatable {
        let title: String
        let showsBadge: Bool
        
        init(title: String, showsBadge: Bool = false) {
            self.title = title
            self.showsBadge = showsBadge
        }
        
        static func == (lhs: Button, rhs: Button) -> Bool {
            lhs.title == rhs.title && lhs.showsBadge == rhs.showsBadge
        }
    }
    
    lazy var buttonStack: UIStackView = {
        let view = UIStackView()
        view.alignment = .firstBaseline
        view.axis = .horizontal
        return view
    }()
    
    var items: [Button]? {
        didSet {

            self.buttons = items?.map({ (item: Button) -> UIButton in
                let button = UIButton(type: UIButton.ButtonType.system)
                button.setTitle(item.title, for: UIControl.State())
                button.setTitleColor(UIColor.beamGrey, for: UIControl.State())
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
                button.addTarget(self, action: #selector(ButtonBar.buttonTapped(_:)), for: UIControl.Event.touchUpInside)
                return button
            })
            if self.selectedItemIndex == nil {
                UIView.performWithoutAnimation { () -> Void in
                    self.selectedItemIndex = 0
                }
            } else {
                self.updateColors()
            }
            
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    var selectedItemIndex: Int? {
        didSet {
            self.updateColors()
            
            self.sendActions(for: UIControl.Event.valueChanged)
        }
    }
    
    fileprivate var buttons: [UIButton]? {
        willSet {
            if let buttons = buttons {
                for button in buttons {
                    button.removeFromSuperview()
                }
            }
        }
        didSet {
            if let buttons = buttons {
                var idx = 0
                for button in buttons {
                    button.translatesAutoresizingMaskIntoConstraints = true
                    button.frame = self.buttonRectAtIndex(idx)
                    self.addSubview(button)
                    idx += 1
                }
            }
            
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateColors()
        setNeedsDisplay()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateColors()
            setNeedsDisplay()
        }
    }
    
    fileprivate func updateColors() {

        if let buttons = buttons {
            for (index, button) in buttons.enumerated() {
                let deselectedColor = AppearanceValue(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.5)
                button.setTitleColor(self.selectedItemIndex == index ? self.tintColor: deselectedColor, for: UIControl.State())
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let buttons = buttons, buttons.count > 0 {
            for (idx, button) in buttons.enumerated() {
                button.frame = buttonRectAtIndex(idx)
            }
        }
        
    }
    
    fileprivate func buttonRectAtIndex(_ index: Int) -> CGRect {
        if self.buttons?.count ?? 0 > 0 {
            let buttonWidth = self.bounds.width / CGFloat(self.buttons!.count)
            return CGRect(x: buttonWidth * CGFloat(index), y: 0, width: buttonWidth, height: self.bounds.height)
        } else {
            return CGRect.zero
        }
    }
    
    @objc fileprivate func buttonTapped(_ sender: UIButton) {
        if let selectedIndex = self.buttons?.firstIndex(of: sender) {
            self.selectedItemIndex = selectedIndex
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        buttons?.indices.forEach({ (index) in
            if index > 0 {
                let buttonFrame = self.buttonRectAtIndex(index)
                
                guard let context: CGContext = UIGraphicsGetCurrentContext() else {
                    return
                }
                let lineHeight = 0.5 * buttonFrame.height
                context.move(to: CGPoint(x: buttonFrame.minX, y: buttonFrame.midY - lineHeight * 0.5))
                context.setLineWidth(1.0 / UIScreen.main.scale)
                let strokeColor = AppearanceValue(light: .beamSeparator, dark: .beamDarkTableViewSeperator)
                strokeColor.setStroke()
                context.addLine(to: CGPoint(x: buttonFrame.minX, y: buttonFrame.midY + lineHeight * 0.5))
                context.strokePath()
                
            }
            
            if let buttonItem = self.items?[index], buttonItem.showsBadge == true {
                let badgeSize = CGSize(width: 6, height: 6)
                let titleFrame = self.buttons?[index].titleLabel?.frame ?? CGRect.zero
                let buttonFrame = self.buttonRectAtIndex(index)
                
                let xPosition = buttonFrame.origin.x + titleFrame.origin.x + 1 + titleFrame.width
                let yPosition = buttonFrame.origin.y + titleFrame.origin.y + (badgeSize.height / 2)
                let path = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: xPosition, y: yPosition), size: badgeSize))
                self.tintColor.setFill()
                path.fill()
            }
        })
    }
    
}
