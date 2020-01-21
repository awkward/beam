//
//  PostSelfTextPartCell.swift
//  beam
//
//  Created by Robin Speijer on 22-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import RedditMarkdownKit
import TTTAttributedLabel

final class PostSelfTextPartCell: BeamTableViewCell, PostCell {
    
    fileprivate var contentStylesheet: MarkdownStylesheet {
        if !self.showsSummary {
            return MarkdownStylesheet.beamSelfPostStyleSheet(self.userInterfaceStyle == .dark)
        }
        return MarkdownStylesheet.beamStyleSheet(UIFont.TextStyle.footnote, darkmode: self.userInterfaceStyle == .dark)
    }
    
    var onDetailView: Bool = false {
        didSet {
            
        }
    }
    
    var shouldShowSpoilerOverlay: Bool = true
    var shouldShowNSFWOverlay: Bool = true

    @IBOutlet var contentLabel: TTTAttributedLabel!
    @IBOutlet fileprivate var readAllLabel: UILabel!
    
    @IBOutlet fileprivate var spoilerOverlay: UIView!
    @IBOutlet fileprivate var spoilerOverlayTextLabel: UILabel!
    @IBOutlet fileprivate var spoilerOverlayConstraints: [NSLayoutConstraint]!
    
    @IBOutlet fileprivate var contentLabelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate var readAllTopConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var readAllBottomConstraint: NSLayoutConstraint!
    
    var showsSummary = true {
        didSet {
            self.reloadContents()
        }
    }
    
    weak var post: Post? {
        didSet {
            self.reloadContents()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupView()
    }
    
    private func setupView() {
        self.preservesSuperviewLayoutMargins = false
        self.contentView.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        self.spoilerOverlay.layer.cornerRadius = 3
        self.spoilerOverlay.layer.masksToBounds = true
        self.spoilerOverlay.layer.borderWidth = 0.5
        self.spoilerOverlay.isOpaque = true
        
        self.showsSummary = true
    }
    
    func reloadContents() {
        self.contentLabel.numberOfLines = self.showsSummary ? 3: 0
        
        var showReadAll = true

        if self.post?.isContentSpoiler.boolValue == true && self.shouldShowSpoilerOverlay && !self.onDetailView {
            self.contentLabel.isHidden = true
            self.contentLabelHeightConstraint.isActive = true
            
            showReadAll = false
            
            self.spoilerOverlay.isHidden = false
            for constraint in self.spoilerOverlayConstraints {
                constraint.isActive = true
            }
            
            self.spoilerOverlayTextLabel.text = NSLocalizedString("text-may-contain-spoilers-warning", comment: "The message displayed on a text post when it may constain spoilers")
        } else if self.post?.isContentNSFW.boolValue == true && self.shouldShowNSFWOverlay && !self.onDetailView {
            self.contentLabel.isHidden = true
            self.contentLabelHeightConstraint.isActive = true
            
            showReadAll = false
            
            self.spoilerOverlay.isHidden = false
            for constraint in self.spoilerOverlayConstraints {
                constraint.isActive = true
            }
            
            self.spoilerOverlayTextLabel.text = NSLocalizedString("text-may-contain-nsfw-warning", comment: "The message displayed on a text post when it may constain NSFW content")
        } else {
            self.contentLabel.isHidden = false
            self.contentLabelHeightConstraint.isActive = false
            
            showReadAll = self.showsSummary
            
            self.spoilerOverlay.isHidden = true
            for constraint in self.spoilerOverlayConstraints {
                constraint.isActive = false
            }
        }
        
        self.readAllLabel.isHidden = !showReadAll
        self.readAllTopConstraint.isActive = showReadAll
        self.readAllBottomConstraint.isActive = showReadAll
        
        self.layoutIfNeeded()
        
        self.appearanceDidChange()
    }
    
    func reloadLayoutInsets() {
        if self.onDetailView {
            self.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        } else {
            self.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.appearanceDidChange()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.appearanceDidChange()
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesWithStyle(userInterfaceStyle)
        self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesWithStyle(userInterfaceStyle)
        self.contentLabel.setText(post?.markdownString?.attributedStringWithStylesheet(self.contentStylesheet))
        self.readAllLabel.textColor = AppearanceValue(light: UIColor.beam, dark: UIColor.beamPurpleLight)
        
        var containerBackgroundColor = AppearanceValue(light: UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0), dark: UIColor(red: 38 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1.0))
        if self.isHighlighted || self.isSelected {
            containerBackgroundColor = AppearanceValue(light: UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1), dark: UIColor(red: 0.23, green: 0.23, blue: 0.23, alpha: 1))
        }
        self.spoilerOverlay.backgroundColor = containerBackgroundColor
        self.spoilerOverlayTextLabel.backgroundColor = containerBackgroundColor
        self.spoilerOverlayTextLabel.textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
        
        self.spoilerOverlay.layer.borderColor = AppearanceValue(light: UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), dark: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1)).cgColor
        
        if !self.spoilerOverlay.isHidden {
            self.selectedBackgroundView?.backgroundColor = AppearanceValue(light: UIColor.white, dark: UIColor.beamDarkContentBackground)
        }
        
        self.contentLabel.backgroundColor = self.contentView.backgroundColor
        self.readAllLabel.backgroundColor = self.contentView.backgroundColor
        self.contentLabel.isOpaque = true
        self.readAllLabel.isOpaque = true
    }
    
    func link(at point: CGPoint) -> URL? {
        let point = self.contentView.convert(point, to: self.contentLabel)
        let link = self.contentLabel.link(at: point)
        return link?.result.url
    }
    
}
