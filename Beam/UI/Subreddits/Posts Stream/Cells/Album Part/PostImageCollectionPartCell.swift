//
//  PostImageCollectionPartCell.swift
//  beam
//
//  Created by Robin Speijer on 21-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

/// A protocol to communicate image collection part cell user interaction.
protocol PostImageCollectionPartCellDelegate: class {
    
    /// The user tapped on a media object in the part cell.
    func postImageCollectionPartCell(_ cell: PostImageCollectionPartCell, didTapMediaObjectAtIndex mediaIndex: Int)
    
    /// The user tapped on a more button in the part cell.
    func postImageCollectionPartCell(_ cell: PostImageCollectionPartCell, didTapMoreButtonAtIndex mediaIndex: Int)
    
}

/**
A part of the post cell that represents an image album. Internally, it has a UICollectionView in it.
*/
final class PostImageCollectionPartCell: BeamTableViewCell, PostCell {
    
    var post: Post?
    
    var onDetailView: Bool = false
    
    var visibleSubreddit: Subreddit? {
        didSet {
            self.albumView.shouldShowNSFWOverlay = self.visibleSubreddit?.shouldShowNSFWOverlay() ?? UserSettings[.showPrivacyOverlay]
            self.albumView.shouldShowSpoilerOverlay = self.visibleSubreddit?.shouldShowSpoilerOverlay() ?? UserSettings[.showSpoilerOverlay]
        }
    }
    
    /// Media objects that are being displayed in the part cell.
    var mediaObjects: [MediaObject]? {
        didSet {
            
            self.albumView.mediaObjects = self.mediaObjects

        }
    }
    
    /// Delegate to communicate user interaction back.
    weak var delegate: PostImageCollectionPartCellDelegate?
    
    @IBOutlet fileprivate var albumView: StreamAlbumView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.albumView.delegate = self
    }
    
    func imageViewAtIndex(_ index: Int) -> UIImageView? {
        return self.albumView.albumItemViewAtIndex(index)?.mediaImageView
    }
    
    func albumItemViewAtLocation(_ location: CGPoint) -> StreamAlbumItemView? {
        return self.albumView.albumItemViewForLocation(location)
    }
    
    func mediaItemAtLocation(_ location: CGPoint) -> MediaObject? {
        return self.albumView.mediaObjectForLocation(location)
    }
    
}

extension PostImageCollectionPartCell: StreamAlbumViewDelegate {
    
    func albumView(_ collectionView: StreamAlbumView, didTapItemView itemView: StreamAlbumItemView, atIndex index: Int) {
        if itemView.moreCount > 0 {
            self.delegate?.postImageCollectionPartCell(self, didTapMoreButtonAtIndex: index)
        } else {
            self.delegate?.postImageCollectionPartCell(self, didTapMediaObjectAtIndex: index)
        }
    }

}
