//
//  TableViewHeaderBannerView.swift
//  Beam
//
//  Created by Rens Verhoeven on 15-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Trekker
import SDWebImage

class TableViewHeaderBannerView: BeamView {

    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var tapButton: UIButton!
    @IBOutlet var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.iconImageView.accessibilityIgnoresInvertColors = true
    }
    
    var notification: BannerNotification? {
        didSet {
            self.textLabel.text = self.notification?.message
            if let imageName = self.notification?.iconName {
                self.iconImageView.image = UIImage(named: imageName)
            } else if let iconURL = self.notification?.iconURL {
                self.iconImageView.sd_setImage(with: iconURL as URL, placeholderImage: nil)
            } else {
                self.iconImageView.image = nil
            }
            
        }
    }
    
    var tapHandler: ((_ notification: BannerNotification) -> Void)?
    var closeHandler: ((_ notification: BannerNotification) -> Void)?
    
    class func bannerView(_ notification: BannerNotification, tapHandler: ((_ notification: BannerNotification) -> Void)?, closeHandler: ((_ notification: BannerNotification) -> Void)?) -> TableViewHeaderBannerView {
        let bannerView = UINib(nibName: "TableViewHeaderBannerView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! TableViewHeaderBannerView
        bannerView.notification = notification
        bannerView.tapHandler = tapHandler
        bannerView.closeHandler = closeHandler
        bannerView.sizeToFit()
        return bannerView
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.textLabel.textColor = DisplayModeValue(UIColor(red: 62 / 255, green: 61 / 255, blue: 66 / 255, alpha: 1.0), darkValue: UIColor.white.withAlphaComponent(0.8))
        self.closeButton.tintColor = DisplayModeValue(UIColor.black.withAlphaComponent(0.4), darkValue: UIColor.white.withAlphaComponent(0.4))
        self.backgroundColor = DisplayModeValue(UIColor(red: 245 / 255, green: 245 / 255, blue: 248 / 255, alpha: 1.0), darkValue: UIColor.beamDarkBackgroundColor())
        
        self.setNeedsDisplay()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.iconImageView.layer.cornerRadius = (self.notification?.useRoundIcon ?? false) ? self.iconImageView.bounds.height / 2: 0
        self.iconImageView.layer.masksToBounds = true
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let seperatorHeight = 1 / UIScreen.main.scale
        let seperatorRect = CGRect(x: 0, y: rect.maxY - seperatorHeight, width: rect.width, height: seperatorHeight)
        let seperatorColor = self.displayMode == .dark ? UIColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1) : UIColor(red: 0.84, green: 0.83, blue: 0.85, alpha: 1)
        
        let seperatorPath = UIBezierPath(rect: seperatorRect)
        seperatorColor.setFill()
        seperatorPath.fill()
    }
    
    @IBAction fileprivate func close(_ sender: UIButton) {
        if let notification = self.notification {
            notification.markAsShown()
            self.closeHandler?(notification)
        }
    }
    
    @IBAction fileprivate func tapped(_ sender: UIButton) {
        if let notification = self.notification {
            Trekker.default.track(event: TrekkerEvent(event: "Tapped promotion banner", properties: ["Type": notification.analyticsTitle]))
            notification.markAsShown()
            self.tapHandler?(notification)
        }
    }
    
    override func sizeToFit() {
        var rect = self.frame
        rect.size = self.intrinsicContentSize
        self.frame = rect
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 62)
    }
    
    override var intrinsicContentSize: CGSize {
        return self.sizeThatFits(UIScreen.main.bounds.size)
    }
}
