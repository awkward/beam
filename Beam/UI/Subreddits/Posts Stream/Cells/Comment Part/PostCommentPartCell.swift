//
//  PostCommentPartCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 14-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import TTTAttributedLabel
import Snoo
import RedditMarkdownKit

final class PostCommentPartCell: BeamTableViewCell, PostCell {

    @IBOutlet var commentView: UIView!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var contentLabel: TTTAttributedLabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var topConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.commentView.layer.cornerRadius = 3
        self.commentView.layer.masksToBounds = true
        self.commentView.isOpaque = true
    }
    
    var needsTopSpacing: Bool = true {
        didSet {
            self.topConstraint.constant = self.needsTopSpacing ? 8: 0
        }
    }
    
    var contentStyleSheet: MarkdownStylesheet {
        return MarkdownStylesheet.beamCommentsStyleSheet(self.displayMode == .dark)
    }
    
    //This cell doesn't do anything with the post
    weak var post: Post?
    
    var onDetailView: Bool = false
    
    weak var comment: Comment? {
        didSet {
            self.authorLabel.text = comment?.author
            self.contentLabel.setText(self.comment?.markdownString?.attributedStringWithStylesheet(self.contentStyleSheet))
            
            if let score = self.comment?.score, let dateString = self.comment?.creationDate?.localizedRelativeTimeString {
                var localizedPoints = NSLocalizedString("points-inline", comment: "")
                if score.intValue == 1 || score.intValue == -1 {
                    localizedPoints = NSLocalizedString("point-inline", comment: "")
                }
                
                self.dateLabel.text = "\(score.intValue) \(localizedPoints), \(dateString)"
            } else {
                self.dateLabel.text = self.comment?.creationDate?.localizedRelativeTimeString
            }
            
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.displayModeDidChange()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.displayModeDidChange()
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let authorIsOriginalPoster = (comment?.author == comment?.post?.author)
        var titleColor = UIColor(red: 12 / 255, green: 11 / 255, blue: 13 / 255, alpha: 1)
        if authorIsOriginalPoster {
            titleColor = UIColor(red: 227 / 255, green: 88 / 255, blue: 45 / 255, alpha: 1)
        } else if self.displayMode == .dark {
            titleColor = UIColor(red: 217 / 255, green: 217 / 255, blue: 217 / 255, alpha: 1.0)
        }
        self.authorLabel.textColor = titleColor
        
        self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesForMode(self.displayMode)
        self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesForMode(self.displayMode)
        self.contentLabel.setText(self.comment?.markdownString?.attributedStringWithStylesheet(self.contentStyleSheet))
        self.dateLabel.textColor = DisplayModeValue(UIColor(red: 127 / 225, green: 127 / 225, blue: 127 / 225, alpha: 1.0), darkValue: UIColor(red: 153 / 225, green: 153 / 225, blue: 153 / 225, alpha: 1.0))
        
        switch displayMode {
        case .dark:
            if self.isHighlighted || self.isSelected {
                self.commentView.backgroundColor = UIColor(red: 0.23, green: 0.23, blue: 0.23, alpha: 1)
            } else {
                self.commentView.backgroundColor = UIColor(red: 38 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1.0)
            }
        case .default:
            if self.isHighlighted || self.isSelected {
                self.commentView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
            } else {
                self.commentView.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0)
            }
        }
        
    }
}
