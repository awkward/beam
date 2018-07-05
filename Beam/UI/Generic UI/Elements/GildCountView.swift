//
//  GildCountView.swift
//  Beam
//
//  Created by Rens Verhoeven on 22-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

@IBDesignable
class GildCountView: BeamView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    fileprivate func setupView() {
        self.textlabel.font = self.font
        
        self.addSubview(self.iconImageView)
        self.addSubview(self.textlabel)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.textlabel.textColor = DisplayModeValue(UIColor(red: 127 / 225, green: 127 / 225, blue: 127 / 225, alpha: 1.0), darkValue: UIColor(red: 153 / 225, green: 153 / 225, blue: 153 / 225, alpha: 1.0))
        self.iconImageView.tintColor = DisplayModeValue(UIColor(red: 250 / 255, green: 212 / 255, blue: 25 / 255, alpha: 1.0), darkValue: UIColor(red: 170 / 255, green: 147 / 255, blue: 35 / 255, alpha: 1.0))
    }
    
    var count: Int = 0 {
        didSet {
            self.textlabel.text = self.text()
            
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }
    
    var font: UIFont = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular) {
        didSet {
            self.textlabel.font = self.font
            
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }
    
    fileprivate let spacing: CGFloat = 4.0
    
    fileprivate let textlabel = UILabel()
    fileprivate let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "gilded_star"))
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }()
    
    func text() -> String {
        return "×\(self.count)"
    }
    
    override var intrinsicContentSize: CGSize {
        let labelSize = self.textlabel.intrinsicContentSize
        let iconSize = self.iconImageView.intrinsicContentSize
        
        var height = iconSize.height
        if labelSize.height > height {
            height = labelSize.height
        }
        let width = iconSize.width + self.spacing + labelSize.width
        return CGSize(width: ceil(width), height: ceil(height))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let labelSize = self.textlabel.intrinsicContentSize
        let iconSize = self.iconImageView.intrinsicContentSize
        
        var xPosition: CGFloat = 0
        
        let iconFrame = CGRect(origin: CGPoint(x: xPosition, y: self.bounds.midY - (iconSize.height / 2)), size: iconSize)
        self.iconImageView.frame = iconFrame
        
        xPosition += iconSize.width
        xPosition += self.spacing
        
        let labelFrame = CGRect(origin: CGPoint(x: xPosition, y: self.bounds.midY - (labelSize.height / 2)), size: labelSize)
        self.textlabel.frame = labelFrame
    }
    
}
