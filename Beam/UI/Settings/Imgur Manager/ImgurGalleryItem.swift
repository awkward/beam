//
//  ImgurGalleryItem.swift
//  Beam
//
//  Created by Rens Verhoeven on 28-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import ImgurKit
import AWKGallery
import SDWebImage

class ImgurGalleryItem: NSObject {
    
    var imgurObject: ImgurObject?
    
    var imgurImage: ImgurImage? {
        return self.imgurObject as? ImgurImage
    }
    
    var size: CGSize? {
        get {
            return self.imgurImage?.imageSize
        }
        set {
            self.imgurImage?.imageSize = newValue
        }
    }
    
    var animated: Bool? {
        get {
            return self.imgurImage?.animated
        }
        set {
            self.imgurImage?.animated = newValue ?? false
        }
    }
    
    var animatedURL: URL? {
        if self.animated == true {
            if let urlString: String = self.imgurImage?.imageURL.absoluteString.replacingOccurrences(of: ".gifv", with: ".mp4") {
                return URL(string: urlString)
            }
        }
        
        return nil
    }
    
    init(object: ImgurObject) {
        self.imgurObject = object
        super.init()
    }
    
}

// MARK: - AWKGalleryItem
extension ImgurGalleryItem: AWKGalleryItem {
    
    @objc var contentURL: URL? {
        if self.animated == true {
            return self.animatedURL
        } else if let URL = self.imgurImage?.imageURL {
            return URL
        } else {
            NSLog("ContentURL String missing")
            return nil
        }
    }
    
    @objc var contentType: AWKGalleryItemContentType {
        get {
            if self.animated == true && self.animatedURL?.pathExtension == "mp4" {
                return AWKGalleryItemContentType.repeatingMovie
                // Some gifs end with .gif.png in the Cherry response (very weird).
            } else if self.animated == true || self.contentURL?.pathExtension == "gif" || self.contentURL?.absoluteString.contains(".gif.png") == true {
                return AWKGalleryItemContentType.animatedImage
            } else {
                return AWKGalleryItemContentType.image
            }
        }
        set {
            
        }
    }
    
    @objc var placeholderImage: UIImage? {
        return nil
    }
    
    @objc var contentData: Any? {
        get {
            if let url = self.contentURL {
                return SDImageCache.shared().imageFromDiskCache(forKey: url.absoluteString)
            }
            return nil
        } set {
            if let url = self.contentURL, let contentData = contentData as? UIImage {
                SDImageCache.shared().store(contentData, forKey: url.absoluteString)
            }
        }
    }
    
    @objc var contentSize: CGSize {
        return self.imgurImage?.imageSize ?? CGSize.zero
    }
    
    fileprivate var isAlbumItem: Bool {
        return false
    }
    
    @objc var attributedTitle: NSAttributedString? {
        return nil
    }
    
    @objc var attributedSubtitle: NSAttributedString? {
        return nil
    }
    
}

func == (lhs: ImgurGalleryItem, rhs: ImgurGalleryItem) -> Bool {
    return lhs.contentURL == rhs.contentURL
}

extension ImgurKit.ImgurObject {
    
    var galleryItem: ImgurGalleryItem {
        get {
            return ImgurGalleryItem(object: self)
        }
        set {
            // Don't do anything. It's already saved.
        }
    }
    
}
