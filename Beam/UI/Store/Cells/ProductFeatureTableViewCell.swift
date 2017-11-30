//
//  ProductFeatureTableViewCell.swift
//  beam
//
//  Created by Rens Verhoeven on 04-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class ProductFeatureTableViewCell: BeamTableViewCell {
    
    var feature: StoreProductFeature? {
        didSet {
            self.iconImageView.image = feature?.icon
            self.titleLabel.text = feature?.heading?.uppercased(with: Locale.current)
            self.descriptionLabel.text = feature?.subheading
        }
    }
    
    @IBOutlet fileprivate var iconImageView: UIImageView!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var descriptionLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.feature = nil
    }

    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.titleLabel.textColor = DisplayModeValue(UIColor.beamPurple(), darkValue: UIColor.beamPurpleLight())
        self.descriptionLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.8)
        self.iconImageView.tintColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
    }
    
}
