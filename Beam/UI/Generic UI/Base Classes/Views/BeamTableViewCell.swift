//
//  BeamTableViewCell.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum BeamTableViewCellTextColorType {
    case `default`
    case followAppTintColor
    case disabled
    case destructive
}

class BeamTableViewCell: UITableViewCell, BeamAppearance {
    
    var textColorType = BeamTableViewCellTextColorType.default {
        didSet {
            self.appearanceDidChange()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        appearanceDidChange()
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if self.window != nil {
            self.selectedBackgroundView = UIView(frame: bounds)
            self.selectedBackgroundView?.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        } else {
            self.selectedBackgroundView = nil
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            appearanceDidChange()
        }
    }
    
    func appearanceDidChange() {
        let tintColor = UIColor.beam
        
        if self.tintColor != tintColor {
            //Changing the tintColor of a view while it's already that color causes UILabel, UIButton and UIImageView to redraw, even when it's not needed. Expecially for UIButton and UIImageView this is a big performance hit
            self.tintColor = tintColor
        }
        
        self.isOpaque = true
        self.contentView.isOpaque = true
        
        self.backgroundColor = AppearanceValue(light: UIColor.white, dark: UIColor.beamDarkContentBackground)
        self.selectedBackgroundView?.backgroundColor = AppearanceValue(light: UIColor.beamGreyExtraExtraLight, dark: UIColor.beamGreyDark)
        self.contentView.backgroundColor = self.backgroundColor
        
        let textColor = UIColor.label
        let detailTextColor = UIColor.secondaryLabel
        if self.detailTextLabel?.textColor != detailTextColor {
            self.detailTextLabel?.textColor = detailTextColor
        }
        switch self.textColorType {
        case .default:
            if self.textLabel?.textColor != textColor {
                self.textLabel?.textColor = textColor
            }
        case .followAppTintColor:
            if self.textLabel?.textColor != tintColor {
                self.textLabel?.textColor = tintColor
            }
        case .disabled:
            let disabledTextColor = UIColor.tertiaryLabel
            if self.textLabel?.textColor != disabledTextColor {
                self.textLabel?.textColor = disabledTextColor
            }
        case .destructive:
            let destructiveTextColor = AppearanceValue(light: UIColor.beamRedDarker, dark: UIColor.beamRed)
            if self.textLabel?.textColor != destructiveTextColor {
                self.textLabel?.textColor = destructiveTextColor
            }
        }
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if self.textColorType != .disabled {
            super.setHighlighted(highlighted, animated: animated)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if self.textColorType != .disabled {
            super.setSelected(selected, animated: animated)
        }
    }

}
