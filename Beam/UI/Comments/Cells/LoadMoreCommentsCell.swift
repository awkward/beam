//
//  LoadMoreCommentsCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 29-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

class LoadMoreCommentsCell: BaseCommentCell {
    
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var activityIndicatorView: UIActivityIndicatorView!
    
    var loading = false
    
    override func reloadContents() {
        super.reloadContents()
        
        if let morePlaceholder = self.comment as? MoreComment, let count = morePlaceholder.count, count.intValue > 0 {
            self.titleLabel.text = AWKLocalizedString("load-more-comments-with-count").replacingOccurrences(of: "[REPLY-COUNT]", with: "\(morePlaceholder.count!.intValue)")
        } else {
            self.titleLabel.text = AWKLocalizedString("load-more-comments-no-count")
        }
        
        self.activityIndicatorView.isHidden = !self.loading
        if self.loading {
            self.activityIndicatorView.startAnimating()
        } else {
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.titleLabel.textColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        self.activityIndicatorView.tintColor = DisplayModeValue(UIColor.lightGray, darkValue: UIColor.white)
    }

}
