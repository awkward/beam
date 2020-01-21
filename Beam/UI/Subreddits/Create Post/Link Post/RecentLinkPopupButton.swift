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
            self.appearanceDidChange()
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
        button.setImage(UIImage(named: "close_small"), for: UIControl.State())
        button.addTarget(self, action: #selector(RecentLinkPopupButton.closeTapped(_:)), for: UIControl.Event.touchUpInside)
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
            
            self.appearanceDidChange()
        }
    }
    
    fileprivate func addSubviewConstraints() {
        
        self.addConstraint(NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.topMargin, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.bottomMargin, multiplier: 1.0, constant: 0))
        
        self.addConstraint(NSLayoutConstraint(item: self.closeButton, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerYWithinMargins, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.closeButton, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: 22))
        self.addConstraint(NSLayoutConstraint(item: self.closeButton, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: 22))
        
        self.addConstraint(NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.leadingMargin, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.closeButton, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self.closeButton, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.trailingMargin, multiplier: 1.0, constant: 7))
        
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        self.closeButton.tintColor = AppearanceValue(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.5)
        
        let textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
        
        let attributedString = NSMutableAttributedString(string: "\(AWKLocalizedString("add-recent-link-to-post"))\n", attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)])
        if let link = self.link {
            attributedString.append(NSAttributedString(string: link, attributes: [NSAttributedString.Key.foregroundColor: textColor.withAlphaComponent(0.5), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)]))
        }
        
        self.textLabel.attributedText = attributedString
        self.setNeedsLayout()
        self.invalidateIntrinsicContentSize()
        
        self.setNeedsDisplay()
    }
    
    @objc fileprivate func closeTapped(_ sender: AnyObject) {
        self.sendActions(for: UIControl.Event.editingDidEnd)
    }
    
    override func draw(_ rect: CGRect) {
        var image: UIImage?
        switch userInterfaceStyle {
        case .dark:
            image = UIImage(named: "popup-background-dark")
        default:
            image = UIImage(named: "popup-background")
        }
        
        if let image = image {
            image.draw(in: rect)
        }        
    }
    
}
