//
//  SubredditInfoDescriptionCell.swift
//  beam
//
//  Created by Rens Verhoeven on 19-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import TTTAttributedLabel
import RedditMarkdownKit

protocol SubredditInfoDescriptionCellDelegate: class {
    
    func readMoreTappedForSubredditInfoDescriptionCell(_ cell: SubredditInfoDescriptionCell)
    
}

class SubredditInfoDescriptionCell: BeamTableViewCell {
    
    @IBOutlet fileprivate var readMoreButton: UIButton!
    @IBOutlet fileprivate var contentLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet var contentLabelReadMoreSpaceConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var contentLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet var contentLabel: TTTAttributedLabel!
    
    weak var delegate: SubredditInfoDescriptionCellDelegate?
    
    var isExpanded: Bool = false {
        didSet {
            self.setNeedsUpdateConstraints()
            self.readMoreButton.isHidden = isExpanded
        }
    }
    
    var subreddit: Subreddit? {
        didSet {
            self.reloadData()
            self.layoutIfNeeded()
            self.isExpanded = self.contentLabel.sizeThatFits(CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height <= self.contentLabelHeightConstraint.constant
        }
    }
    
    fileprivate var contentStylesheet: MarkdownStylesheet {
        return MarkdownStylesheet.beamSelfPostStyleSheet(self.displayMode == .dark)
    }
    
    fileprivate func reloadData() {
        self.contentLabel.linkAttributes = TTTAttributedLabel.beamLinkAttributesForMode(self.displayMode)
        self.contentLabel.activeLinkAttributes = TTTAttributedLabel.beamActiveLinkAttributesForMode(self.displayMode)
        self.contentLabel.setText(self.subreddit?.descriptionTextMarkdownString?.attributedStringWithStylesheet(self.contentStylesheet))
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        self.contentLabelBottomConstraint.isActive = self.isExpanded
        self.contentLabelHeightConstraint.isActive = !self.isExpanded
        self.contentLabelReadMoreSpaceConstraint.isActive = !self.isExpanded
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.reloadData()
    }

    @IBAction fileprivate func readMoreButtonTapped(_ sender: AnyObject) {
        self.delegate?.readMoreTappedForSubredditInfoDescriptionCell(self)
    }
}
