//
//  ImageSpoilerView.swift
//  beam
//
//  Created by Robin Speijer on 16-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

final class ImageSpoilerView: BeamView {

    weak var sourceView: UIView?
    fileprivate (set) var opened = false
    fileprivate var animationCompleted = false
    fileprivate var backgroundLayer = CALayer()
    fileprivate var cancelling = false
    
    fileprivate var firstTouchTimeInterval: TimeInterval?
    
    fileprivate var buttonLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.beamGreyLighter().cgColor
        layer.lineWidth = 1
        return layer
    }()
    
    fileprivate var backgroundMaskLayer: CAShapeLayer?
    
    var buttonLabel: UILabel = {
        let label = UILabel(frame: CGRect())
        label.backgroundColor = UIColor.clear
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = UIColor.beamGreyLighter()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AWKLocalizedString("nsfw")
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupView()
    }
    
    fileprivate func setupView() {
        self.isUserInteractionEnabled = true
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = true
        
        self.backgroundLayer.frame = self.bounds
        self.layer.insertSublayer(self.backgroundLayer, below: self.layer)
        self.layer.insertSublayer(self.buttonLayer, above: self.backgroundLayer)
        self.backgroundMaskLayer?.frame = self.backgroundLayer.bounds
        
        self.addSubview(self.buttonLabel)
        let labelX = NSLayoutConstraint(item: self.buttonLabel, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        let labelY = NSLayoutConstraint(item: self.buttonLabel, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        self.addConstraints([labelX, labelY])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundLayer.frame = self.layer.bounds
        self.backgroundMaskLayer?.frame = self.backgroundLayer.bounds
        self.backgroundMaskLayer?.anchorPoint = CGPoint(x: self.backgroundMaskLayer?.bounds.midX ?? 0, y: self.backgroundMaskLayer?.bounds.midY ?? 0)
        
        let buttonSize = CGSize(width: 77, height: 77)
        self.buttonLayer.frame = CGRect(origin: CGPoint(x: self.bounds.midX - 0.5 * buttonSize.width, y: self.bounds.midY - 0.5 * buttonSize.height), size: buttonSize)
        self.buttonLayer.path = CGPath(ellipseIn: self.buttonLayer.bounds, transform: nil)
        
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.backgroundColor = UIColor.clear
        
        switch self.displayMode {
        case .dark:
            self.backgroundLayer.backgroundColor = UIColor(red: 31 / 255.0, green: 31 / 255.0, blue: 31 / 255.0, alpha: 1).cgColor
        default:
            self.backgroundLayer.backgroundColor = UIColor.beamGreyExtraExtraLight().cgColor
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.firstTouchTimeInterval = Date.timeIntervalSinceReferenceDate
        
        if !self.opened {
            self.animationCompleted = false
            self.beginPreviewAnimation()
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.cancelling && !self.opened && self.firstTouchTimeInterval != nil && self.firstTouchTimeInterval! - Date.timeIntervalSinceReferenceDate > -0.01 && !self.animationCompleted {
            self.reset()
            self.beginPreviewAnimation(0.32)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { () -> Void in
                self.opened = true
                self.animationCompleted = true
            })
            
        } else if !self.opened && self.animationCompleted {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: { () -> Void in
                self.opened = true
            })
        } else if !self.opened {
            self.beginCancelAnimation()
        } else {
            self.resignFirstResponder()
        }
        
        super.touchesEnded(touches, with: event)
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        self.beginCancelAnimation()
    }
    
    fileprivate func beginPreviewAnimation(_ duration: CFTimeInterval = 0.8) {
        guard !self.cancelling else {
            return
        }
        
        self.buttonLabel.isHidden = true
        self.buttonLayer.isHidden = true
        
        self.backgroundMaskLayer = CAShapeLayer()
        
        self.backgroundMaskLayer!.frame = self.backgroundLayer.bounds
        self.backgroundMaskLayer!.fillRule = kCAFillRuleEvenOdd
        
        let startSize: CGFloat = 5
        let startRect = CGRect(x: self.backgroundMaskLayer!.bounds.midX - 0.5 * startSize, y: self.backgroundMaskLayer!.bounds.midY - 0.5 * startSize, width: startSize, height: startSize)
        
        let path = UIBezierPath(rect: self.backgroundLayer.bounds)
        path.append(UIBezierPath(ovalIn: startRect))
        
        self.backgroundMaskLayer!.path = path.cgPath
        self.backgroundLayer.mask = self.backgroundMaskLayer!
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn))
        CATransaction.setCompletionBlock { () -> Void in
            self.animationCompleted = true
        }
        
        let largestSide = max(self.backgroundLayer.bounds.width, self.backgroundLayer.bounds.height)
        let scale = largestSide / (startSize * 0.5)
        self.backgroundLayer.transform = CATransform3DMakeScale(scale, scale, 1)
        
        CATransaction.commit()
    }
    
    fileprivate func beginCancelAnimation() {
        guard !self.cancelling else {
            return
        }
        
        self.cancelling = true
        if let presentationLayer = self.backgroundLayer.presentation() {
            self.backgroundLayer.transform = presentationLayer.transform
        }
        
        self.opened = false
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        CATransaction.setCompletionBlock { () -> Void in
            self.reset()
        }
        self.backgroundLayer.transform = CATransform3DIdentity
        CATransaction.commit()
    }
    
    func reset() {
        self.cancelling = false
        self.opened = false
        self.animationCompleted = false
        
        self.firstTouchTimeInterval = nil
        
        self.buttonLabel.isHidden = false
        self.buttonLayer.isHidden = false
        
        self.backgroundLayer.transform = CATransform3DIdentity
        self.backgroundLayer.mask = nil
        self.backgroundMaskLayer = nil
        
        self.backgroundLayer.setNeedsDisplay()
        
    }
    
}
