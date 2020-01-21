//
//  PostImageCollectionPartItemCell.swift
//  beam
//
//  Created by Robin Speijer on 22-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import SDWebImage

class PostImageCollectionPartItemCell: BeamCollectionViewCell, MediaImageLoader, MediaCellMediaLabels {
    
    var imageOperation: SDWebImageOperation?

    var shouldShowNSFWOverlay: Bool = true {
        didSet {
            self.reloadEffectView()
        }
    }
    var shouldShowSpoilerOverlay: Bool = true {
        didSet {
            self.reloadEffectView()
        }
    }
    
    var mediaObject: MediaObject? {
        didSet {
            guard self.mediaObject != nil else { return }
            
            self.progressView.isHidden = false
            self.startImageLoading()
            self.reloadEffectView()
            self.reloadMediaLabels()
        }
    }
    
    var preferredThumbnailSize: CGSize {
        return self.mediaImageView.bounds.size
    }
    
    var moreCount = 0 {
        didSet {
            self.reloadEffectView()
            self.moreLabel.text = "+ \(moreCount)"
        }
    }
    
    func reloadEffectView() {
        if (self.contentIsNSFW && self.shouldShowNSFWOverlay) || (self.contentIsSpoiler && self.shouldShowSpoilerOverlay) {
            self.effectView.isHidden = false
            self.moreLabel.isHidden = true
        } else {
            self.effectView.isHidden = true
        }
        if self.moreCount > 0 {
            self.effectView.isHidden = false
            self.moreLabel.isHidden = false
        }
    }
    
    func imageLoadingCompleted() {
        self.progressView.isHidden = true
    }
    
    func progressDidChange(_ progress: CGFloat) {
        self.progressView.progress = progress
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        self.progressView.color = userInterfaceStyle == .dark ?  UIColor.white: UIColor.beamGreyExtraLight
    }
    
    @IBOutlet var progressView: CircularProgressView!
    @IBOutlet var mediaImageView: UIImageView!
    @IBOutlet var effectView: UIVisualEffectView!
    @IBOutlet var moreLabel: UILabel!
    @IBOutlet var mediaLabelImageViews: [UIImageView]?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.stopImageLoading()
        
        self.moreCount = 0
        self.mediaImageView.image = nil
        self.progressView.isHidden = true
        self.progressView.progress = 0
    }
    
    deinit {
        self.stopImageLoading()
    }
    
}

extension PostImageCollectionPartItemCell: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        DispatchQueue.main.async { () -> Void in
            self.progressDidChange(CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite))
        }
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        let image = UIImage.downscaledImageWithFileURL(location, options: DownscaledImageOptions())
        if let cacheKey = downloadTask.originalRequest?.url?.absoluteString {
            SDImageCache.shared.store(image, forKey: cacheKey, toDisk: true)
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.mediaImageView.image = image
            self.imageLoadingCompleted()
            self.imageOperation = nil
        })
        
    }
    
}
