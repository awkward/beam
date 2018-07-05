//
//  GalleryPostBottomView.swift
//  beam
//
//  Created by Robin Speijer on 12-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import AWKGallery

class GalleryPostBottomView: UIView {
    
    @IBOutlet var metadataView: PostMetadataView!
    @IBOutlet var toolbarView: PostToolbarView!
    
    var post: Post? {
        didSet {
            self.metadataView.post = self.post
            self.toolbarView.post = self.post
        }
    }
    
    var shouldShowSubreddit: Bool = false {
        didSet {
            self.metadataView.shouldShowSubreddit = self.shouldShowSubreddit
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.metadataView.highlightButtons = false
        self.toolbarView.isOpaque = false
        self.metadataView.isOpaque = false
        self.toolbarView.shouldShowSeperator = false
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let lineWidth = 1.0 / UIScreen.main.scale
        context.setLineWidth(lineWidth)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        
        let y = self.toolbarView.frame.minY - 0.5 * lineWidth
        context.move(to: CGPoint(x: self.layoutMargins.left, y: y))
        context.addLine(to: CGPoint(x: self.bounds.width - self.layoutMargins.left, y: y))
        context.strokePath()
    }
    
}

extension GalleryPostBottomView: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .bottom
    }
    
}
