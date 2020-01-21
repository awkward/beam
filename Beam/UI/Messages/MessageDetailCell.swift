//
//  MessageDetailCell.swift
//  beam
//
//  Created by Robin Speijer on 18-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import TTTAttributedLabel
import RedditMarkdownKit

class MessageDetailCell: BeamTableViewCell, MessageObjectCell {
    
    @IBOutlet var authorButton: BeamPlainButton!
    @IBOutlet var contentLabel: TTTAttributedLabel!
    
    weak var delegate: MessageObjectCellDelegate?
    
    var sentMessage = false
    
    fileprivate var contentStylesheet: MarkdownStylesheet {
        return MarkdownStylesheet.beamStyleSheet(UIFont.TextStyle.subheadline, darkmode: self.userInterfaceStyle == .dark)
    }
    
    var message: Message? {
        didSet {
            var author = self.message?.author ?? "reddit"
            if self.sentMessage {
                author = self.message?.destination ?? "reddit"
            }
            
            if self.sentMessage {
                let textColor = AppearanceValue(light: UIColor.beamGreyExtraDark, dark: UIColor.white)
                let fontSize: CGFloat = FontSizeController.adjustedFontSize(17)
                let textFont = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.semibold)
                
                let typeTextColor = AppearanceValue(light: UIColor.beamGreyExtraDark.withAlphaComponent(0.5), dark: UIColor.white.withAlphaComponent(0.5))
                let typeTextFont = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.semibold)
                
                let authorAttributedString = NSAttributedString(string: author, attributes: [NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.font: textFont])
                let typeAttributedString = NSMutableAttributedString(string: AWKLocalizedString("sent-to"), attributes: [NSAttributedString.Key.foregroundColor: typeTextColor, NSAttributedString.Key.font: typeTextFont])
                typeAttributedString.append(authorAttributedString)
                self.authorButton.setAttributedTitle(typeAttributedString, for: UIControl.State())
            } else {
                self.authorButton.setTitle(author, for: UIControl.State.normal)
            }
            
            self.appearanceDidChange()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.authorButton.addTarget(self, action: #selector(MessageDetailCell.authorTapped(_:)), for: UIControl.Event.touchUpInside)
    }
    
    @objc fileprivate func authorTapped(_ sender: AnyObject) {
        if let message = self.message {
            self.delegate?.messageObjectCell(self, didTapUsernameOnMessage: message)
        }
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        self.authorButton.setTitleColor(AppearanceValue(light: UIColor.beamGreyExtraDark, dark: UIColor(red: 217 / 255.0, green: 217 / 255.0, blue: 217 / 255.0, alpha: 1)), for: UIControl.State())
        
        self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesWithStyle(userInterfaceStyle)
        self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesWithStyle(userInterfaceStyle)
        self.contentLabel.setText(self.message?.markdownString?.attributedStringWithStylesheet(self.contentStylesheet))
    }

}
