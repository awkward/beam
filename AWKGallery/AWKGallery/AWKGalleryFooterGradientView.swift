//
//  AWKGradientView.swift
//  AWKGallery
//
//  Created by Robin Speijer on 12-10-15.
//  Copyright © 2015 Robin Speijer. All rights reserved.
//

import UIKit

public class AWKGalleryFooterGradientView: UIView {
    
    override open class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    // The relative middle location of the gradient
    @objc open var relativeMidLocation: Float = 0.5 {
        didSet {
            self.configureView()
        }
    }
    
    fileprivate var gradientLayer: CAGradientLayer {
        if let layer = self.layer as? CAGradientLayer {
            return layer
        } else {
            fatalError("AWKGradientView layer should be of type CAGradientLayer")
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
        self.gradientLayer.colors = [UIColor.clear.cgColor, UIColor.galleryBackgroundColor().withAlphaComponent(0.76).cgColor, UIColor.galleryBackgroundColor().withAlphaComponent(0.9).cgColor]
        self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        self.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        self.gradientLayer.locations = [0, NSNumber(value: self.relativeMidLocation) , 1]
        self.gradientLayer.setNeedsDisplay()
    }

}
