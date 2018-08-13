//
//  ProfileSwitchButton.swift
//  Beam
//
//  Created by Rens Verhoeven on 15-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

final class ProfileSwitchButton: UIControl {

    lazy fileprivate var titleLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = self.tintColor
        return label
    }()
    
    var showArrow: Bool = true {
        didSet {
            self.setNeedsLayout()
            self.invalidateIntrinsicContentSize()
        }
    }
    
    var title: String = "Profile" {
        didSet {
            self.titleLabel.text = self.title
            self.setNeedsLayout()
            self.invalidateIntrinsicContentSize()
        }
    }
    
    init () {
        super.init(frame: CGRect.zero)
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
    
    func setupView() {
        self.isOpaque = false
        self.addSubview(self.titleLabel)
        self.titleLabel.text = self.title
        self.setNeedsLayout()
        self.invalidateIntrinsicContentSize()
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        if self.showArrow {
            let size = self.arrowSize
            let arrowOffset: CGFloat = 2
            let point = CGPoint(x: self.bounds.width - size.width, y: (self.bounds.midY - (size.height / 2)) + arrowOffset)
            //// Bezier Drawing
            let bezierPath = UIBezierPath()
            bezierPath.move(to: CGPoint(x: point.x + 4.52, y: point.y + 4.74))
            bezierPath.addCurve(to: CGPoint(x: point.x + 3.48, y: point.y + 4.74), controlPoint1: CGPoint(x: point.x + 4.23, y: point.y + 5.09), controlPoint2: CGPoint(x: point.x + 3.77, y: point.y + 5.09))
            bezierPath.addLine(to: CGPoint(x: point.x + 0.15, y: point.y + 0.64))
            bezierPath.addCurve(to: CGPoint(x: point.x + 0.47, y: point.y), controlPoint1: CGPoint(x: point.x - 0.14, y: point.y + 0.29), controlPoint2: CGPoint(x: point.x + 0, y: point.y))
            bezierPath.addLine(to: CGPoint(x: point.x + 7.53, y: point.y))
            bezierPath.addCurve(to: CGPoint(x: point.x + 7.85, y: point.y + 0.64), controlPoint1: CGPoint(x: point.x + 8, y: point.y), controlPoint2: CGPoint(x: point.x + 8.14, y: point.y + 0.29))
            bezierPath.addLine(to: CGPoint(x: point.x + 4.52, y: point.y + 4.74))
            bezierPath.close()
            bezierPath.usesEvenOddFillRule = true
            
            self.tintColor.setFill()
            bezierPath.fill()
        }

    }
    
    var arrowSize: CGSize = CGSize(width: 8, height: 5)
    var titleToArrowSpacing: CGFloat = 3
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var titleLabelWidthOffset = self.arrowSize.width + self.titleToArrowSpacing
        if !self.showArrow {
            titleLabelWidthOffset = 0
        }
        self.titleLabel.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width - titleLabelWidthOffset, height: self.bounds.size.height)
        
        self.setNeedsDisplay()
    }
    
    override var intrinsicContentSize: CGSize {
        var titleLabelWidthOffset = self.arrowSize.width + self.titleToArrowSpacing
        if !self.showArrow {
            titleLabelWidthOffset = 0
        }
        let labelSize = self.titleLabel.intrinsicContentSize
        return CGSize(width: labelSize.width + titleLabelWidthOffset, height: 34)
    }
    
    override func sizeToFit() {
        var frame = self.frame
        frame.size = self.intrinsicContentSize
        self.frame = frame
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.titleLabel.textColor = self.tintColor
        self.setNeedsDisplay()
    }

}
