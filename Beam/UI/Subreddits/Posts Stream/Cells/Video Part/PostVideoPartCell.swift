//
//  PostVideoPartCell.swift
//  beam
//
//  Created by Rens Verhoeven on 14/08/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//

import UIKit
import Snoo

final class PostVideoPartCell: UITableViewCell, PostCell {
    
    @IBOutlet fileprivate var linkPreviewView: PostLinkPreviewView?
    
    var linkContainerViewFrame: CGRect {
        return self.linkPreviewView?.frame ?? .zero
    }
    
    weak var post: Post? {
        didSet {
            if let urlString = self.post?.urlString, let link = URL(string: urlString) {
                self.linkPreviewView?.changeLink(link: link, post: self.post, allowNSFW: !self.shouldShowNSFWOverlay, allowSpoiler: !self.shouldShowSpoilerOverlay)
            } else {
                self.linkPreviewView?.changeLink(link: nil, post: self.post, allowNSFW: !self.shouldShowNSFWOverlay, allowSpoiler: !self.shouldShowSpoilerOverlay)
            }
            
        }
    }
    
    var onDetailView: Bool = false
    
    var shouldShowSpoilerOverlay: Bool = true
    var shouldShowNSFWOverlay: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupView()
    }
    
    private func setupView() {
        self.preservesSuperviewLayoutMargins = false
        self.contentView.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        
        self.linkPreviewView?.isEnabled = false
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    class func heightForLink(isVideo: Bool, forWidth width: CGFloat) -> CGFloat {
        return 200
    }
    
}
