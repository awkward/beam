//
//  MultiredditTableViewCell.swift
//  beam
//
//  Created by Robin Speijer on 13-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

class MultiredditTableViewCell: BeamTableViewCell {
    
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subredditsLabel: UILabel!
    @IBOutlet fileprivate var multiredditImageView: UIImageView!
    @IBOutlet fileprivate var multiredditImageLabel: UILabel?
    
    var multireddit: Multireddit? {
        didSet {
            let displayName = multireddit?.displayName
            self.titleLabel.text = multireddit?.displayName
            self.subredditsLabel.text = "\(multireddit?.subreddits?.count ?? 0) subreddits"
            
            if let displayName = displayName?.uppercased(), displayName.characters.count > 0 {
                let firstChar = displayName.substring(to: displayName.index(displayName.startIndex, offsetBy: 1))
                self.multiredditImageLabel?.text = firstChar
            } else {
                self.multiredditImageLabel?.text = nil
            }
            
        }
    }
    
    var multiredditImageURL: URL? {
        didSet {
            self.reloadImage()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.titleLabel.minimumScaleFactor = 0.8
        
        let maskView = UIImageView(image: self.createPlaceholderImage())
        maskView.contentMode = UIViewContentMode.scaleToFill
        maskView.backgroundColor = UIColor.clear
        self.multiredditImageView?.mask = maskView
    }
    
    fileprivate func reloadImage() {
        if let url = self.multiredditImageURL {
            self.multiredditImageView.sd_setImage(with: url, completed: { (image, error, cacheType, url) -> Void in
                if image === nil {
                    self.multiredditImageView.image = nil
                    self.multiredditImageLabel?.isHidden = false
                }
                else{
                    self.multiredditImageLabel?.isHidden = true
                }
            })
        } else {
            self.multiredditImageView.sd_cancelCurrentImageLoad()
            self.multiredditImageView.image = nil
            self.multiredditImageLabel?.isHidden = false
        }
    }
    
    fileprivate func createPlaceholderImage() -> UIImage {
        let bounds = self.multiredditImageView.bounds
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        let bezierPath = UIBezierPath(ovalIn: bounds)
        let fillColor = (self.displayMode == .dark) ? UIColor.beamDarkBackgroundColor() : UIColor.beamGreyExtraExtraLight()
        fillColor.setFill()
        bezierPath.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.titleLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        
        self.subredditsLabel.textColor = DisplayModeValue(UIColor.black.withAlphaComponent(0.8), darkValue: UIColor.white.withAlphaComponent(0.8))
        
        switch self.displayMode {
        case .dark:
            self.multiredditImageView.backgroundColor = UIColor.beamGreyDark()
            self.multiredditImageLabel?.textColor = UIColor.beamGreyLighter()
            let view = UIView()
            view.backgroundColor = UIColor(red:0.16, green:0.16, blue:0.16, alpha:1)
            self.selectedBackgroundView = view
        case .default:
            self.multiredditImageView.backgroundColor = UIColor.beamGreyExtraExtraLight()
            self.multiredditImageLabel?.textColor = UIColor.beamGreyLighter()
            self.selectedBackgroundView = nil
        }
        
    }
    
    

}
