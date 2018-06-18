//
//  VoteButton.swift
//  beam
//
//  Created by Robin Speijer on 14-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

enum VoteButtonArrowDirection {
    case up
    case down
}

public let VoteButtonDidBeginAnimatingNotification = "VoteButtonDidBeginAnimatingNotification"
public let VoteButtonDidEndAnimatingNotification = "VoteButtonDidEndAnimatingNotification"

@IBDesignable
class VoteButton: UIControl {
    
    var color = UIColor(red: 170 / 255, green: 168 / 255, blue: 179 / 255, alpha: 1) {
        didSet {
            if !self.voted {
                self.face.strokeColor = self.color
                self.face.arrowColor = self.color
            }
            
        }
    }
    
    fileprivate let faceSize = CGSize(width: 22, height: 22)
    
    fileprivate var face = VoteButtonFace(frame: CGRect.zero)
    
    var animating = false {
        didSet {
            self.isUserInteractionEnabled = !self.animating
            if self.animating {
                NotificationCenter.default.post(name: Notification.Name(rawValue: VoteButtonDidBeginAnimatingNotification), object: self)
            } else {
                self.animatingDidEndBlock?()
                self.animatingDidEndBlock = nil
                NotificationCenter.default.post(name: Notification.Name(rawValue: VoteButtonDidEndAnimatingNotification), object: self)
            }
        }
    }
    
        /// Block called after animating has been set to false. This block is called on the main thread
    var animatingDidEndBlock: (() -> Void)?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    func setupView() {
        
        self.face.faceColor = UIColor.clear
        self.face.strokeColor = self.color
        self.face.arrowColor = self.color
        
        NotificationCenter.default.addObserver(self, selector: #selector(VoteButton.voteButtonDidBeginAnimating(_:)), name: NSNotification.Name(rawValue: VoteButtonDidBeginAnimatingNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VoteButton.voteButtonDidEndAnimating(_:)), name: NSNotification.Name(rawValue: VoteButtonDidEndAnimatingNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.face.superview != self {
            self.addSubview(self.face)
        }
        
        self.face.bounds = CGRect(origin: CGPoint.zero, size: self.faceSize)
        self.face.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
    }
    
    override var intrinsicContentSize: CGSize {
        return self.faceSize
    }
    
    var arrowDirection: VoteButtonArrowDirection {
        get {
            return self.face.arrowView.direction
        }
        set {
            self.face.arrowView.direction = newValue
        }
    }
    
    fileprivate var animateInteraction: Bool = false
    var voted: Bool = false {
        didSet {
            if oldValue != voted {
                if !animateInteraction {
                    if self.animating {
                        //We can't cancel the animation but we do want to the correct state
                        self.animatingDidEndBlock = {
                            self.changeFace()
                        }
                    } else {
                        self.changeFace()
                    }
                } else {
                    if self.animating {
                        //We can't cancel the animation but we do want to the correct state
                        self.animatingDidEndBlock = {
                            self.changeFaceAnimated()
                        }
                    } else {
                        self.changeFaceAnimated()
                    }
                    
                }
            }
        }
    }
    
    fileprivate func changeFace() {
        let newFace = VoteButtonFace(frame: self.face.frame)
        self.configureFace(newFace)
        self.addSubview(newFace)
        self.face.removeFromSuperview()
        self.face = newFace
    }
    
    fileprivate func changeFaceAnimated() {
        if self.voted {
            self.animateToVoted()
        } else {
            self.animateToDefault()
        }
    }
    
    fileprivate func configureFace(_ face: VoteButtonFace) {
        face.arrowView.direction = self.arrowDirection
        
        if !self.voted {
            face.faceColor = UIColor.clear
            face.strokeColor = self.color
            face.arrowColor = self.color
        } else if self.arrowDirection == .up {
            face.faceColor = UIColor.beamRed()
            face.strokeColor = UIColor.clear
            face.arrowColor = UIColor.white
        } else {
            face.faceColor = UIColor.beamBlue()
            face.strokeColor = UIColor.clear
            face.arrowColor = UIColor.white
        }
    }
    
    func setVoted(_ voted: Bool, animated: Bool) {
        self.animateInteraction = animated
        self.voted = voted
        self.animateInteraction = false
    }
    
    fileprivate func animateToVoted() {
        self.animating = true
        
        let votedFace = VoteButtonFace(frame: self.face.frame)
        self.configureFace(votedFace)
        
        votedFace.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        votedFace.isHidden = true
        let directionMultiplier = self.arrowDirection == .up ? 1.0 : -1.0
        votedFace.arrowView.transform = CGAffineTransform(translationX: 0, y: CGFloat(directionMultiplier) * votedFace.bounds.height)
        votedFace.arrowView.alpha = 0
        
        self.insertSubview(votedFace, belowSubview: self.face)
        
        func animateVotedFace() {
            votedFace.isHidden = false
            
            CATransaction.begin()
            
            UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                votedFace.arrowView.transform = CGAffineTransform.identity
                votedFace.arrowView.alpha = 1
                }, completion: nil)
            
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [], animations: {
                votedFace.transform = CGAffineTransform.identity
            }, completion: { (completed) in
                    if completed == false {
                        votedFace.removeFromSuperview()
                    } else {
                        self.face = votedFace
                    }
                    self.animating = false
            })
            
            CATransaction.commit()
        }
        
        self.face.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        UIView.animate(withDuration: 0.15, delay: 0, options: [UIViewAnimationOptions.curveEaseOut], animations: { () -> Void in
            self.face.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            self.face.alpha = 0
            }, completion: { (_) in
                animateVotedFace()
        })
        
    }
    
    fileprivate func animateToDefault() {
        self.animating = true
        let newFace = VoteButtonFace(frame: self.face.frame)
        self.configureFace(newFace)
        
        newFace.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        newFace.alpha = 0
        self.insertSubview(newFace, belowSubview: self.face)
        
        func animateDefaultFace() {
            newFace.isHidden = false
            UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                newFace.transform = CGAffineTransform.identity
                newFace.alpha = 1
            }, completion: { (completed) in
                if completed == false {
                    newFace.removeFromSuperview()
                } else {
                    self.face = newFace
                }
                self.animating = false
            })
        }
        
        self.face.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        CATransaction.begin()
        
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.face.arrowView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.face.arrowView.alpha = 0
        }, completion: nil)
        
        UIView.animate(withDuration: 0.2, delay: 0.075, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.face.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.face.alpha = 0
        }, completion: { (completed) in
                if completed {
                    animateDefaultFace()
                }
        })
        
        CATransaction.commit()
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.alpha = isHighlighted ? 0.6: 1
        }
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func voteButtonDidBeginAnimating(_ notification: Notification?) {
        self.isEnabled = false
    }
    
    @objc fileprivate func voteButtonDidEndAnimating(_ notification: Notification?) {
        self.isEnabled = true
    }
    
}

// MARK: -
class VoteButtonFace: UIView {
    
    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    fileprivate var shapeLayer: CAShapeLayer {
        return self.layer as! CAShapeLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.accessibilityIgnoresInvertColors = true

        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = false
        self.isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.isUserInteractionEnabled = false
    }
    
    var arrowView: VoteButtonArrow = {
        let arrow = VoteButtonArrow(frame: CGRect(x: 0, y: 0, width: 10, height: 6))
        arrow.fillColor = UIColor.beamGreyLighter()
        return arrow
        }()
    
    var faceColor = UIColor.clear {
        didSet {
            self.shapeLayer.fillColor = self.faceColor.cgColor
        }
    }
    
    var strokeColor = UIColor.gray {
        didSet {
            self.shapeLayer.strokeColor = self.strokeColor.cgColor
        }
    }
    
    var arrowColor = UIColor.gray {
        didSet {
            self.arrowView.fillColor = self.arrowColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.shapeLayer.lineWidth = 1
        if self.shapeLayer.path == nil {
            self.shapeLayer.path = CGPath(ellipseIn: self.bounds.insetBy(dx: self.shapeLayer.lineWidth, dy: self.shapeLayer.lineWidth), transform: nil)
        }
        
        let arrowSize = CGSize(width: 10, height: 6)
        self.arrowView.bounds = CGRect(origin: CGPoint(), size: arrowSize)
        
        let yOffset: CGFloat = self.arrowView.direction == .up ? -0.5: 0.5
        self.arrowView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY + yOffset)
        if self.arrowView.superview != self {
            self.addSubview(self.arrowView)
        }
        
    }
    
}

// MARK: -
class VoteButtonArrow: UIView {
    
    override class var layerClass: AnyClass {
        return VoteButtonArrowLayer.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.fillColor = UIColor.gray
        
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        self.fillColor = UIColor.gray
        
        super.init(frame: frame)
    }
    
    fileprivate var arrowLayer: VoteButtonArrowLayer {
        return self.layer as! VoteButtonArrowLayer
    }
    
    var direction: VoteButtonArrowDirection {
        get {
            return self.arrowLayer.direction
        }
        set {
            self.arrowLayer.direction = newValue
        }
    }
    
    var fillColor: UIColor {
        didSet {
            self.arrowLayer.fillColor = self.fillColor.cgColor
        }
    }
    
}

private class VoteButtonArrowLayer: CAShapeLayer {
    
    var direction: VoteButtonArrowDirection = .up {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        let arrowPath = self.direction == .up ? self.createUpArrowPath() : self.createDownArrowPath()
        self.path = arrowPath.cgPath
        self.lineJoin = kCALineJoinRound
    }
    
    fileprivate func createUpArrowPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 5.66, y: 0.32))
        path.addLine(to: CGPoint(x: 9.81, y: 5.22))
        path.addCurve(to: CGPoint(x: 9.42, y: 6), controlPoint1: CGPoint(x: 10.17, y: 5.65), controlPoint2: CGPoint(x: 10, y: 6))
        path.addLine(to: CGPoint(x: 0.58, y: 6))
        path.addCurve(to: CGPoint(x: 0.19, y: 5.22), controlPoint1: CGPoint(x: 0, y: 6), controlPoint2: CGPoint(x: -0.17, y: 5.65))
        path.addLine(to: CGPoint(x: 4.34, y: 0.32))
        path.addCurve(to: CGPoint(x: 5.66, y: 0.32), controlPoint1: CGPoint(x: 4.7, y: -0.11), controlPoint2: CGPoint(x: 5.29, y: -0.11))
        path.close()
        path.usesEvenOddFillRule = true
        return path
    }
    
    fileprivate func createDownArrowPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 5.46, y: 5.5))
        path.addCurve(to: CGPoint(x: 4.17, y: 5.5), controlPoint1: CGPoint(x: 5.1, y: 5.92), controlPoint2: CGPoint(x: 4.53, y: 5.93))
        path.addLine(to: CGPoint(x: 0.19, y: 0.77))
        path.addCurve(to: CGPoint(x: 0.54, y: 0), controlPoint1: CGPoint(x: -0.17, y: 0.34), controlPoint2: CGPoint(x: -0, y: 0))
        path.addLine(to: CGPoint(x: 9.09, y: 0))
        path.addCurve(to: CGPoint(x: 9.44, y: 0.77), controlPoint1: CGPoint(x: 9.64, y: 0), controlPoint2: CGPoint(x: 9.8, y: 0.34))
        path.addLine(to: CGPoint(x: 5.46, y: 5.5))
        path.close()
        path.usesEvenOddFillRule = true
        return path
    }
    
}
