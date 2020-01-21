//
//  AboutTableViewCell.swift
//  beam
//
//  Created by Rens Verhoeven on 28-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum AboutTableViewCellIcon: String {
    case Reddit = "about_icon_reddit"
    case Facebook = "about_icon_facebook"
    case Twitter = "about_icon_twitter"
    case Safari = "about_icon_safari"
}

class AboutTableViewCell: BeamTableViewCell {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var iconImageView: UIImageView!
    
    var icon: AboutTableViewCellIcon = .Reddit {
        didSet {
            self.iconImageView.image = UIImage(named: self.icon.rawValue)
        }
    }
    
    var title: String = "" {
        didSet {
            self.titleLabel.text = self.title
        }
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        self.iconImageView.tintColor = UIColor(red: 0.71, green: 0.71, blue: 0.71, alpha: 1)
        
        switch self.userInterfaceStyle {
        case .dark:
            self.titleLabel?.textColor = UIColor(red: 217 / 255.0, green: 217 / 255.0, blue: 217 / 255.0, alpha: 1)
        default:
            self.titleLabel?.textColor = UIColor.beamGreyExtraDark
        }
    }

}
