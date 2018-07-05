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

class MessageCell: BeamTableViewCell, MessageObjectCell {
    
    @IBOutlet var unreadIndicator: UnreadIndicator!
    @IBOutlet var replyIndicator: UIImageView!
    @IBOutlet var authorButton: BeamPlainButton!
    @IBOutlet var ageLabel: UILabel!
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var contentLabel: TTTAttributedLabel!
    
    weak var delegate: MessageObjectCellDelegate?
    
    var sentMessage = false
    
    fileprivate var contentStylesheet: MarkdownStylesheet {
        return MarkdownStylesheet.beamStyleSheet(UIFontTextStyle.footnote, darkmode: self.displayMode == .dark)
    }
    
    var message: Message? {
        didSet {
            self.subjectLabel.text = self.message?.subject
            self.ageLabel.text = self.message?.creationDate?.localizedRelativeTimeString
            self.reloadIndicator()
            self.displayModeDidChange()
        }
    }
    
    var authorText: NSAttributedString? {
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        let textFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.semibold)
        
        let typeTextFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        
        var author = self.message?.author ?? "reddit"
        if self.sentMessage {
            author = self.message?.destination ?? "reddit"
        }
        let authorAttributedString = NSAttributedString(string: author, attributes: [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: textFont])
        
        if self.sentMessage {
            let typeAttributedString = NSMutableAttributedString(string: AWKLocalizedString("sent-to"), attributes: [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: typeTextFont])
            typeAttributedString.append(authorAttributedString)
            return typeAttributedString
        }
        return authorAttributedString
    }
    
    func reloadIndicator() {
        self.replyIndicator.isHidden = !self.sentMessage
        self.unreadIndicator.isHidden = self.sentMessage || self.message?.unread?.boolValue == false
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.authorButton.addTarget(self, action: #selector(MessageCell.authorTapped(_:)), for: UIControlEvents.touchUpInside)
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
        self.replyIndicator.tintColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor.white.withAlphaComponent(0.65))
        
        self.authorButton.setAttributedTitle(self.authorText, for: UIControlState())
        
        self.subjectLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        
        self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesForMode(self.displayMode)
        self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesForMode(self.displayMode)
        self.contentLabel.setText(self.message?.markdownString?.attributedStringWithStylesheet(self.contentStylesheet))
    }
}
