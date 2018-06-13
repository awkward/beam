//
//  AWKGradientView.swift
//  AWKGallery
//
//  Created by Robin Speijer on 12-10-15.
//  Copyright © 2015 Robin Speijer. All rights reserved.
//

import UIKit

@objc public class AWKGradientView: UIView {
    
    override open class var layerClass : AnyClass {
        return CAGradientLayer.self
    }
    
    fileprivate var gradientLayer: CAGradientLayer {
        if let layer = self.layer as? CAGradientLayer {
            return layer
        } else {
            fatalError("AWKGradientView layer should be of type CAGradientLayer")
        }
    }
    
    @objc open var fromColor = UIColor.clear {
        didSet {
            self.gradientLayer.colors = [self.fromColor.cgColor, self.toColor.cgColor]
            self.gradientLayer.setNeedsDisplay()
        }
    }
    
    @objc open var toColor = UIColor.galleryBackgroundColor().withAlphaComponent(0.5) {
        didSet {
            self.gradientLayer.colors = [self.fromColor.cgColor, self.toColor.cgColor]
            self.gradientLayer.setNeedsDisplay()
        }
    }
    
    @objc open var direction = UILayoutConstraintAxis.vertical {
        didSet {
            if self.direction == .vertical {
                self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
                self.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            } else {
                self.gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
                self.gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            }
            self.gradientLayer.setNeedsDisplay()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        self.configureView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configureView()
    }
    
    fileprivate func configureView() {
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
        
        self.gradientLayer.locations = [NSNumber(value: 0 as Double), NSNumber(value: 1 as Double)]
        self.fromColor = UIColor.clear
        self.toColor = UIColor.galleryBackgroundColor().withAlphaComponent(0.5)
        self.direction = .vertical
    }

}
