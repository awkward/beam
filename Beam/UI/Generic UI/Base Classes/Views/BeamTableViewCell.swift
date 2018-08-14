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

class BeamTableViewCell: UITableViewCell, DynamicDisplayModeView {
    
    var textColorType = BeamTableViewCellTextColorType.default {
        didSet {
            self.displayModeDidChange()
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if self.window != nil {
            self.selectedBackgroundView = UIView(frame: bounds)
            self.selectedBackgroundView?.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
            self.registerForDisplayModeChangeNotifications()
        } else {
            self.selectedBackgroundView = nil
            self.unregisterForDisplayModeChangeNotifications()
        }
    }
    
    deinit {
        self.unregisterForDisplayModeChangeNotifications()
    }
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        self.displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        let tintColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        
        if self.tintColor != tintColor {
            //Changing the tintColor of a view while it's already that color causes UILabel, UIButton and UIImageView to redraw, even when it's not needed. Expecially for UIButton and UIImageView this is a big performance hit
            self.tintColor = tintColor
        }
        
        self.isOpaque = true
        self.contentView.isOpaque = true
        
        self.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.selectedBackgroundView?.backgroundColor = DisplayModeValue(UIColor.beamGreyExtraExtraLight(), darkValue: UIColor.beamGreyDark())
        self.contentView.backgroundColor = self.backgroundColor
        
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        let detailTextColor = textColor.withAlphaComponent(0.8)
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
            let disabledTextColor = textColor.withAlphaComponent(0.5)
            if self.textLabel?.textColor != disabledTextColor {
                self.textLabel?.textColor = disabledTextColor
            }
        case .destructive:
            let destructiveTextColor = DisplayModeValue(UIColor.beamRedDarker(), darkValue: UIColor.beamRed())
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
