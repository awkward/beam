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
        return MarkdownStylesheet.beamStyleSheet(UIFontTextStyle.subheadline, darkmode: self.displayMode == .dark)
    }
    
    var message: Message? {
        didSet {
            var author = self.message?.author ?? "reddit"
            if self.sentMessage {
                author = self.message?.destination ?? "reddit"
            }
            
            if self.sentMessage {
                let textColor = DisplayModeValue(UIColor.beamGreyExtraDark(), darkValue: UIColor.white)
                let fontSize: CGFloat = FontSizeController.adjustedFontSize(17)
                let textFont = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.semibold)
                
                let typeTextColor = DisplayModeValue(UIColor.beamGreyExtraDark().withAlphaComponent(0.5), darkValue: UIColor.white.withAlphaComponent(0.5))
                let typeTextFont = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.semibold)
                
                let authorAttributedString = NSAttributedString(string: author, attributes: [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: textFont])
                let typeAttributedString = NSMutableAttributedString(string: AWKLocalizedString("sent-to"), attributes: [NSAttributedStringKey.foregroundColor: typeTextColor, NSAttributedStringKey.font: typeTextFont])
                typeAttributedString.append(authorAttributedString)
                self.authorButton.setAttributedTitle(typeAttributedString, for: UIControlState())
            } else {
                self.authorButton.setTitle(author, for: UIControlState.normal)
            }
            
            self.displayModeDidChange()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.authorButton.addTarget(self, action: #selector(MessageDetailCell.authorTapped(_:)), for: UIControlEvents.touchUpInside)
    }
    
    @objc fileprivate func authorTapped(_ sender: AnyObject) {
        if let message = self.message {
            self.delegate?.messageObjectCell(self, didTapUsernameOnMessage: message)
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.authorButton.setTitleColor(DisplayModeValue(UIColor.beamGreyExtraDark(), darkValue: UIColor(red: 217 / 255.0, green: 217 / 255.0, blue: 217 / 255.0, alpha: 1)), for: UIControlState())
        
        self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesForMode(self.displayMode)
        self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesForMode(self.displayMode)
        self.contentLabel.setText(self.message?.markdownString?.attributedStringWithStylesheet(self.contentStylesheet))
    }

}
