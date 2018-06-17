//
//  PostMetaDataPartCell.swift
//  beam
//
//  Created by Rens Verhoeven on 14-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

final class PostMetaDataPartCell: BeamTableViewCell, PostCell {
    
    @IBOutlet var metadataView: PostMetadataView!
    
    weak var post: Post? {
        didSet {
            self.metadataView.post = self.post
        }
    }
    
    var onDetailView: Bool = false
    
    // MARK: - Layout
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()

    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 22)
    }
}
