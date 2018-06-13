//
//  MessageCell.swift
//  beam
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import RedditMarkdownKit
import TTTAttributedLabel

class NotificationCell: BeamTableViewCell, MessageObjectCell {
    
    @IBOutlet var unreadIndicator: UnreadIndicator!
    @IBOutlet var authorButton: BeamPlainButton!
    @IBOutlet var metadataLabel: UILabel!
    @IBOutlet var contentLabel: TTTAttributedLabel!
    
    weak var delegate: MessageObjectCellDelegate?

    fileprivate var contentStylesheet: MarkdownStylesheet {
        return MarkdownStylesheet.beamStyleSheet(UIFontTextStyle.footnote, darkmode: self.displayMode == .dark)
    }
    
    var message: Message? {
        didSet {
            self.unreadIndicator.isHidden = self.message?.unread?.boolValue == false
            self.metadataLabel.text = self.metadataText
            
            self.displayModeDidChange()
            
        }
    }
    
    var authorText: NSAttributedString? {
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        let textFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.semibold)
        
        let typeTextColor = DisplayModeValue(UIColor.black.withAlphaComponent(0.5), darkValue: UIColor.white.withAlphaComponent(0.5))
        let typeTextFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        
        if let author = self.message?.author {
            let authorAttributedString = NSMutableAttributedString(string: author, attributes: [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: textFont])
            if let typeString = self.message?.subject {
                let string = " · \(typeString)"
                authorAttributedString.append(NSAttributedString(string: string, attributes: [NSAttributedStringKey.foregroundColor: typeTextColor, NSAttributedStringKey.font: typeTextFont]))
            }
            return authorAttributedString
        }
        return nil
    }
    
    var metadataText: String? {
        var metadataItems = [String]()
        
        if let agoString = self.message?.creationDate?.localizedRelativeTimeString {
            metadataItems.append(agoString)
        }
        
        if let postTitle = self.message?.postTitle {
            metadataItems.append(postTitle)
        }
        
        return metadataItems.joined(separator: " · ")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.authorButton.addTarget(self, action: #selector(NotificationCell.authorTapped(_:)), for: UIControlEvents.touchUpInside)
    }
    
    @objc fileprivate func authorTapped(_ sender: AnyObject) {
        if let message = self.message {
            self.delegate?.messageObjectCell(self, didTapUsernameOnMessage: message)
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.unreadIndicator.backgroundColor = self.contentView.backgroundColor
        self.unreadIndicator.tintColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        self.metadataLabel.textColor = DisplayModeValue(UIColor.black.withAlphaComponent(0.5), darkValue: UIColor.white.withAlphaComponent(0.5))

        self.authorButton.setAttributedTitle(self.authorText, for: UIControlState())
        
        self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesForMode(self.displayMode)
        self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesForMode(self.displayMode)
        self.contentLabel.setText(self.message?.markdownString?.attributedStringWithStylesheet(self.contentStylesheet))
    }

}
