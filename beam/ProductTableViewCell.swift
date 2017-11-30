//
//  ProductTableViewCell.swift
//  beam
//
//  Created by Robin Speijer on 17-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import StoreKit

class ProductTableViewCell: BeamTableViewCell {
    
    var product: StoreProduct? {
        didSet {
            self.backgroundImageView.image = self.product?.icon
            self.iconImageView.image = self.product?.icon
            
            let storeObject: SKProduct? = self.product?.storeObject
            
            let locale: Locale = Locale.current
            
            var heading: String? = self.product?.heading
            if let title: String = storeObject?.localizedTitle {
                heading = title
            }
            heading = heading?.uppercased(with: locale)
            
            if let heading: String = heading {
                let attributes: [String: NSNumber] =  [NSKernAttributeName: NSNumber(value: 1.4)]
                self.headingLabel.attributedText = NSAttributedString(string: heading, attributes: attributes)
            } else {
                self.headingLabel.text = nil
            }
            if let storeObject: SKProduct = storeObject {
                self.subheadingLabel.text = storeObject.localizedDescription
            } else {
                self.subheadingLabel.text = self.product?.subheading
            }
            
            if let storeObject: SKProduct = storeObject {
                self.viewButton.isEnabled = AppDelegate.shared.productStoreController.availableStoreProducts?.contains(storeObject) == true
            } else {
                self.viewButton.isEnabled = false
            }
            
            if self.viewButton.isEnabled == true {
                if self.product?.isOnSale == true {
                    var price: NSNumber = NSNumber(value: 0 as Float)
                    if let objectPrice: NSNumber = storeObject?.price {
                        price = objectPrice
                    }
                    if price.floatValue <= 0 {
                        self.viewButton.setTitle(AWKLocalizedString("free-price").uppercased(with: locale), for: UIControlState())
                    } else {
                       self.viewButton.setTitle(AWKLocalizedString("on-sale").uppercased(with: locale), for: UIControlState())
                    }
                    
                } else {
                     self.viewButton.setTitle(AWKLocalizedString("view-pack").uppercased(with: locale), for: UIControlState())
                }
                self.viewButton.alpha = 1
                self.borderView.alpha = 0
                self.viewButton.isOutlined = true
            } else {
                self.viewButton.setTitle(AWKLocalizedString("coming-soon").uppercased(with: locale), for: UIControlState())
                self.viewButton.alpha = 0.5
                self.borderView.alpha = 0.7
                self.viewButton.isOutlined = false
            }
            self.displayModeDidChange()
        }
    }
    
    @IBOutlet fileprivate var backgroundImageView: UIImageView!
    @IBOutlet fileprivate var iconImageView: UIImageView!
    @IBOutlet fileprivate var headingLabel: UILabel!
    @IBOutlet fileprivate var subheadingLabel: UILabel!
    @IBOutlet fileprivate (set) internal var viewButton: OutlinedButton!
    @IBOutlet fileprivate var blurView: UIVisualEffectView!
    @IBOutlet var borderView: UIView!
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.blurView.effect = DisplayModeValue(UIBlurEffect(style: .extraLight), darkValue: UIBlurEffect(style: .dark))
        self.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkBackgroundColor())
        self.contentView.backgroundColor = self.backgroundColor
        self.backgroundImageView.backgroundColor = DisplayModeValue(UIColor.beamBackground(), darkValue: UIColor.beamDarkContentBackgroundColor())
        self.headingLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.subheadingLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.8)
        self.borderView.backgroundColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        
        if self.viewButton.isEnabled {
            if self.product?.isOnSale == true{
                self.viewButton.titleColor = UIColor(red: 208/255, green: 46/255, blue: 56/255, alpha: 1)
            } else {
                self.viewButton.titleColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
            }
        } else {
            self.viewButton.titleColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        }
    
    }
    
}
