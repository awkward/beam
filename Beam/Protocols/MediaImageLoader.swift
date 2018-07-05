//
//  MediaObjectImageCell.swift
//  beam
//
//  Created by Robin Speijer on 22-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import Snoo
import SDWebImage

protocol MediaImageLoader: class {
    
    // Required stored properties:
    var mediaObject: MediaObject? { get set }
    var mediaImageView: UIImageView! { get }
    var imageOperation: SDWebImageOperation? { get set }
    var preferredThumbnailSize: CGSize { get }
    
    // Required functions
    func imageLoadingCompleted()
    func progressDidChange(_ progress: CGFloat)
    
    // Implemented by extension:
    func startImageLoading()
    func stopImageLoading()
    func mediaURLString() -> String?
}

extension MediaImageLoader {
    
    func mediaURLString() -> String? {
        guard self.mediaObject != nil else {
            return nil
        }
        var mediaURLString: String?
        AppDelegate.shared.managedObjectContext.performAndWait { () -> Void in
            if let urlString = self.mediaObject?.thumbnailWithSize(self.preferredThumbnailSize)?.urlString {
                mediaURLString = urlString
            } else if let url = self.mediaObject?.smallThumbnailURL {
                mediaURLString = url.absoluteString
            } else {
                mediaURLString = self.mediaObject?.contentURLString
            }
        }
        return mediaURLString
    }
    
    func startImageLoading() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] () -> Void in
            let URLString = self?.mediaURLString()
            if let URLString = URLString, let url = URL(string: URLString) {
                if let cachedImage = SDImageCache.shared().imageFromDiskCache(forKey: URLString) {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self?.mediaImageView.image = cachedImage
                        self?.imageLoadingCompleted()
                    })
                } else {
                    self?.imageOperation = AppDelegate.shared.imageLoader.startDownloadingImageWithURL(url, progressHandler: { [weak self] (totalBytesWritten, totalBytesExpectedToWrite) in
                        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
                        self?.progressDidChange(progress)
                        }, completionHandler: { [weak self] (image) in
                            DispatchQueue.main.async(execute: { () -> Void in
                                self?.mediaImageView.image = image
                                self?.imageLoadingCompleted()
                            })
                    })
                }
                
            } else {
                self?.stopImageLoading()
            }
        }
        
    }
    
    func stopImageLoading() {
        self.imageOperation?.cancel()
    }
    
}
