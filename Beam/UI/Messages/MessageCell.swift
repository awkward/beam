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
        return MarkdownStylesheet.beamStyleSheet(UIFont.TextStyle.footnote, darkmode: self.userInterfaceStyle == .dark)
    }
    
    var message: Message? {
        didSet {
            self.subjectLabel.text = self.message?.subject
            self.ageLabel.text = self.message?.creationDate?.localizedRelativeTimeString
            self.reloadIndicator()
            self.appearanceDidChange()
        }
    }
    
    var authorText: NSAttributedString? {
        let textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
        let textFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.semibold)
        
        let typeTextFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        
        var author = self.message?.author ?? "reddit"
        if self.sentMessage {
            author = self.message?.destination ?? "reddit"
        }
        let authorAttributedString = NSAttributedString(string: author, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: textFont])
        
        if self.sentMessage {
            let typeAttributedString = NSMutableAttributedString(string: AWKLocalizedString("sent-to"), attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: typeTextFont])
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
        
        self.authorButton.addTarget(self, action: #selector(MessageCell.authorTapped(_:)), for: UIControl.Event.touchUpInside)
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
        self.replyIndicator.tintColor = AppearanceValue(light: UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), dark: UIColor.white.withAlphaComponent(0.65))
        
        self.authorButton.setAttributedTitle(self.authorText, for: UIControl.State())
        
        self.subjectLabel.textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
        
        self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesWithStyle(userInterfaceStyle)
        self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesWithStyle(userInterfaceStyle)
        self.contentLabel.setText(self.message?.markdownString?.attributedStringWithStylesheet(self.contentStylesheet))
    }
}
