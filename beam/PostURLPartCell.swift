//
//  PostURLPartCell.swift
//  beam
//
//  Created by Robin Speijer on 21-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CherryKit

class PostURLPartCell: BeamTableViewCell, PostCell {

    @IBOutlet fileprivate var linkPreviewView: PostLinkPreviewView!
    
    var linkContainerViewFrame: CGRect {
        return self.linkPreviewView.frame
    }
    
    weak var post: Post? {
        didSet {
            if let urlString = self.post?.urlString, let link = URL(string: urlString) {
                self.linkPreviewView.changeLink(link: link, post: self.post, allowNSFW: !self.shouldShowNSFWOverlay, allowSpoiler: !self.shouldShowSpoilerOverlay)
            } else {
                self.linkPreviewView.changeLink(link: nil, post: self.post, allowNSFW: !self.shouldShowNSFWOverlay, allowSpoiler: !self.shouldShowSpoilerOverlay)
            }
            
        }
    }
    
    var onDetailView: Bool = false
    
    var shouldShowSpoilerOverlay: Bool = true
    var shouldShowNSFWOverlay: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.linkPreviewView.isEnabled = false
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.linkPreviewView.isHighlighted = highlighted
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.linkPreviewView.isSelected = selected
    }

    
    class func heightForLink(isVideo: Bool, forWidth width: CGFloat) -> CGFloat {
        return PostLinkPreviewView.height(for: nil, inWidth: width, isVideoPreview: isVideo)
    }

}
