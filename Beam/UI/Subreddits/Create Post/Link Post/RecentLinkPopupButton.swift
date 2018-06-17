//
//  RecentLinkPopupButton.swift
//  Beam
//
//  Created by Rens Verhoeven on 07-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

@IBDesignable
class RecentLinkPopupButton: BeamControl {
    
    @IBInspectable var link: String? {
        didSet {
            self.displayModeDidChange()
        }
    }
    
    lazy fileprivate var textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.text = "test"
        return label
    }()
    
    lazy fileprivate var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "close_small"), for: UIControlState())
        button.addTarget(self, action: #selector(RecentLinkPopupButton.closeTapped(_:)), for: UIControlEvents.touchUpInside)
        return button
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
        UIView.performWithoutAnimation {
            self.textLabel.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(self.textLabel)
            
            self.closeButton.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(self.closeButton)
            
            //8 for the arrow spacing at the top, 15 for the margin
            self.layoutMargins = UIEdgeInsets(top: 8 + 15, left: 15, bottom: 15, right: 15)
            
            self.addSubviewConstraints()
            
            self.displayModeDidChange()
        }
    }
    
    fileprivate func addSubviewConstraints() {
        
        self.addConstraint(NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.topMargin, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottomMargin, multiplier: 1.0, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: self.closeButton, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.centerYWithinMargins, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.closeButton, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 22))
        self.addConstraint(NSLayoutConstraint(item: self.closeButton, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 22))
        
        self.addConstraint(NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.leadingMargin, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.closeButton, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.closeButton, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.trailingMargin, multiplier: 1.0, constant: 7))
        
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.closeButton.tintColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        
        let attributedString = NSMutableAttributedString(string: "\(AWKLocalizedString("add-recent-link-to-post"))\n", attributes: [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13)])
        if let link = self.link {
            attributedString.append(NSAttributedString(string: link, attributes: [NSAttributedStringKey.foregroundColor: textColor.withAlphaComponent(0.5), NSAttributedStringKey.font: UIFont.systemFont(ofSize: 11)]))
        }
        
        self.textLabel.attributedText = attributedString
        self.setNeedsLayout()
        self.invalidateIntrinsicContentSize()
        
        self.setNeedsDisplay()
    }
    
    @objc fileprivate func closeTapped(_ sender: AnyObject) {
        self.sendActions(for: UIControlEvents.editingDidEnd)
    }
    
    override func draw(_ rect: CGRect) {
        var image: UIImage?
        if self.displayMode == DisplayMode.dark {
            image = UIImage(named: "popup-background-dark")
        } else {
            image = UIImage(named: "popup-background")
        }
        
        if let image = image {
            image.draw(in: rect)
        }
        
    }
    
}
