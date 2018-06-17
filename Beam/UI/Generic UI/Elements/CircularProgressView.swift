//
//  CircularProgressView.swift
//  beam
//
//  Created by Rens Verhoeven on 13-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreGraphics

@IBDesignable
class CircularProgressView: UIView {
    
    fileprivate var animatingLayer = CAShapeLayer()
    fileprivate var lastSourceAngle: CGFloat = 0.0
    fileprivate var currentPaths: [CGPath] = []
    fileprivate var animationDuration: TimeInterval = 0.32
    fileprivate var radius: CGFloat {
        get {
            let width = (fmin(self.bounds.width, self.bounds.height) / 2)
            return width - self.borderWidth
        }
        set {
            //Can't be set!
        }
    }
    
    var progress: CGFloat = 0.0 {
        didSet {
            self.updateWithProgress(self.progress)
        }
    }
    
    var color: UIColor = UIColor.gray {
        didSet {
            self.animatingLayer.fillColor = self.color.cgColor
        }
        
    }
    
    var borderWidth: CGFloat = 2.0 {
        didSet {
            self.configureIndicator()
            self.setNeedsDisplay()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.configureIndicator()
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.lineWidth = self.borderWidth
        path.addArc(withCenter: CGPoint(x: self.bounds.midX, y: self.bounds.midY), radius: self.radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
        self.color.setStroke()
        path.stroke()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.animatingLayer.fillColor = self.color.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.animatingLayer.fillColor = self.color.cgColor
    }
    
    fileprivate func configureIndicator() {
        
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let initialPath = UIBezierPath()
        initialPath.addArc(withCenter: center, radius: self.radius, startAngle: degreeToRadian(-90), endAngle: self.degreeToRadian(-90), clockwise: true)
        self.animatingLayer.path = initialPath.cgPath
        self.animatingLayer.fillColor = self.color.cgColor
        self.lastSourceAngle = self.degreeToRadian(-90)
        
        self.updateWithProgress(self.progress)
        
        self.setNeedsDisplay()
        
        self.animatingLayer.frame = self.bounds
        self.layer.addSublayer(self.animatingLayer)
    }
    
    fileprivate func keyframePathsWithDuration(_ duration: TimeInterval, lastUpdatedAngle: CGFloat, newAngle: CGFloat, radius: CGFloat) -> [CGPath] {
        let frameCount = Int(ceil(duration * 60))
        var array: [CGPath] = []
        for frame in 0...frameCount + 1 {
            let startAngle = self.degreeToRadian(-90)
            
            let angleChange = ((newAngle - lastUpdatedAngle) * CGFloat(frame))
            let endAngle = lastUpdatedAngle + (angleChange / CGFloat(frameCount))
            let path = self.pathWithStartAngle(startAngle, endAngle: endAngle, radius: radius).cgPath
            array.append(path)
        }
        return array
    }
    
    fileprivate func pathWithStartAngle(_ startAngle: CGFloat, endAngle: CGFloat, radius: CGFloat) -> UIBezierPath {
        let clockwise = startAngle < endAngle
        let path = UIBezierPath()
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        
        path.move(to: center)
        path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        path.close()
        return path
    }
    
    fileprivate func degreeToRadian(_ degree: CGFloat) -> CGFloat {
        return (degree * CGFloat.pi) / 180.0
    }
    
    fileprivate func destinationAngleForRatio(_ ratio: CGFloat) -> CGFloat {
        return (self.degreeToRadian((360 * ratio) - 90))
    }
    
    fileprivate func updateWithProgress(_ progress: CGFloat) {
        self.currentPaths.removeAll(keepingCapacity: false)
        let destinationAngle: CGFloat = self.destinationAngleForRatio(progress)
        self.currentPaths = self.keyframePathsWithDuration(self.animationDuration, lastUpdatedAngle: self.lastSourceAngle, newAngle: destinationAngle, radius: self.radius)
        animatingLayer.path = self.currentPaths[(self.currentPaths.count - 1)]
        self.lastSourceAngle = destinationAngle
        let pathAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "path")
        pathAnimation.values = self.currentPaths
        pathAnimation.duration = CFTimeInterval(animationDuration)
        pathAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        pathAnimation.isRemovedOnCompletion = true
        animatingLayer.add(pathAnimation, forKey: "path")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 20, height: 20)
    }
    
}
