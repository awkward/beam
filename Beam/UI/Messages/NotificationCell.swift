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
        return MarkdownStylesheet.beamStyleSheet(UIFont.TextStyle.footnote, darkmode: self.userInterfaceStyle == .dark)
    }
    
    var message: Message? {
        didSet {
            self.unreadIndicator.isHidden = self.message?.unread?.boolValue == false
            self.metadataLabel.text = self.metadataText
            
            self.appearanceDidChange()
            
        }
    }
    
    var authorText: NSAttributedString? {
        let textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
        let textFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.semibold)
        
        let typeTextColor = AppearanceValue(light: UIColor.black.withAlphaComponent(0.5), dark: UIColor.white.withAlphaComponent(0.5))
        let typeTextFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        
        if let author = self.message?.author {
            let authorAttributedString = NSMutableAttributedString(string: author, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: textFont])
            if let typeString = self.message?.subject {
                let string = " · \(typeString)"
                authorAttributedString.append(NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor: typeTextColor, NSAttributedString.Key.font: typeTextFont]))
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
        
        self.authorButton.addTarget(self, action: #selector(NotificationCell.authorTapped(_:)), for: UIControl.Event.touchUpInside)
    }
    
    @objc fileprivate func authorTapped(_ sender: AnyObject) {
        if let message = self.message {
            self.delegate?.messageObjectCell(self, didTapUsernameOnMessage: message)
        }
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        self.unreadIndicator.backgroundColor = self.contentView.backgroundColor
        self.unreadIndicator.tintColor = AppearanceValue(light: UIColor.beam, dark: UIColor.beamPurpleLight)
        self.metadataLabel.textColor = AppearanceValue(light: UIColor.black.withAlphaComponent(0.5), dark: UIColor.white.withAlphaComponent(0.5))

        self.authorButton.setAttributedTitle(self.authorText, for: UIControl.State())
        
        self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesWithStyle(userInterfaceStyle)
        self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesWithStyle(userInterfaceStyle)
        self.contentLabel.setText(self.message?.markdownString?.attributedStringWithStylesheet(self.contentStylesheet))
    }

}
