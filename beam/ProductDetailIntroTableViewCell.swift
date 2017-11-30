//
//  ProductDetailIntroTableViewCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 26-08-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class ProductDetailIntroTableViewCell: BeamTableViewCell {

    @IBOutlet fileprivate var trialStatusLabel: UILabel!
    
    @IBOutlet fileprivate var introLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    var product: StoreProduct? {
        didSet {
            var trialStatus: String?
            if self.product?.hasTrialStarted == true && self.product?.isTrialAvailable == true {
                if self.product?.hasTrialEnded == true {
                    trialStatus = AWKLocalizedString("trial-expired")
                } else {
                    let hoursLeft = self.product!.trialHoursLeft!
                    let minutesLeft = self.product!.trialMinutesLeft!
                    if hoursLeft > 0 {
                        let hours = Int(hoursLeft)
                        let timeString = hours == 1 ? AWKLocalizedString("hour") : AWKLocalizedString("hours")
                        trialStatus = "\(AWKLocalizedString("trial-ends-in")) \(hours) \(timeString)"
                    } else if minutesLeft > 0 {
                        let minutes = Int(minutesLeft)
                        let timeString = minutes == 1 ? AWKLocalizedString("minute") : AWKLocalizedString("minutes")
                        trialStatus = "\(AWKLocalizedString("trial-ends-in")) \(minutes) \(timeString))"
                    }
                }
            }
            if let trialStatusString: String = trialStatus {
                self.trialStatusLabel.text = trialStatusString.uppercased()
                self.trialStatusLabel.isHidden = false
            } else {
                self.trialStatusLabel.isHidden = true
            }
            self.introLabel.text = self.product?.description
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.separatorInset = UIEdgeInsetsMake(0, self.bounds.size.width, 0, 0)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.introLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.trialStatusLabel.textColor = UIColor.beamPurpleLight()
    }
}
