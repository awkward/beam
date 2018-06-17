//
//  GalleryItem.swift
//  beam
//
//  Created by Robin Speijer on 16-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData
import AWKGallery
import SDWebImage

class GalleryItem: NSObject {
    
    var mediaObject: MediaObject?
    
    var size: CGSize? {
        get {
            if let width = self.mediaObject?.width?.floatValue, let height = self.mediaObject?.height?.floatValue {
                return CGSize(width: CGFloat(width), height: CGFloat(height))
            }
            return nil
        }
        set (newSize) {
            self.mediaObject?.managedObjectContext?.performAndWait {
                if let width = newSize?.width, let height = newSize?.height {
                    self.mediaObject?.width = NSNumber(value: Float(width))
                    self.mediaObject?.height = NSNumber(value: Float(height))
                }
            }
        }
    }
    
    var animated: Bool? {
        get {
            if let metaAnimated = (self.mediaObject?.metadataValueForKey("animated") as? NSNumber)?.boolValue {
                return metaAnimated
            } else {
                let contentURLString = self.mediaObject?.contentURLString as NSString?
                return contentURLString?.pathExtension == "gifv" || contentURLString?.pathExtension == "mp4"
            }
        }
        set {
            if newValue == nil {
                self.mediaObject?.removeMetadataValueForKey("animated")
            } else {
                self.mediaObject?.setMetadataValue(NSNumber(value: newValue!), forKey: "animated")
            }
        }
    }
    
    var nsfw: Bool? {
        get {
            if let metaAnimated = (self.mediaObject?.metadataValueForKey("nsfw") as? NSNumber)?.boolValue {
                return metaAnimated
            }
            return nil
        }
        set {
            if newValue == nil {
                self.mediaObject?.removeMetadataValueForKey("nsfw")
            } else {
                self.mediaObject?.setMetadataValue(NSNumber(value: newValue!), forKey: "nsfw")
            }
        }
    }
    
    var animatedURLString: URL? {
        if self.animated == true {
            if let urlString = self.mediaObject?.contentURLString?.replacingOccurrences(of: ".gifv", with: ".mp4") {
                return URL(string: urlString)
            }
        }
        
        return nil
    }
    
    var isMP4GIF: Bool {
        //Check if the URL contains a mp4 extension or in case of Reddit links they will end with .gif, but contain "fm=mp4" (format is mp4) if the URL is a MP4 URL
        return self.mediaObject?.galleryItem.animatedURLString?.pathExtension.contains("mp4") == true || self.mediaObject?.galleryItem.animatedURLString?.absoluteString.contains("fm=mp4") == true
    }
    
    fileprivate var cachedContentType: AWKGalleryItemContentType?
    
    init(mediaObject: MediaObject) {
        self.mediaObject = mediaObject
        super.init()
    }
    
}

// MARK: - AWKGalleryItem
extension GalleryItem: AWKGalleryItem {
    
    @objc var contentURL: URL? {
        if self.animated == true {
            return self.animatedURLString
        } else if let urlString = mediaObject?.contentURLString, let url = URL(string: urlString) {
            return url
        } else {
            NSLog("ContentURL String missing")
            return nil
        }
    }
    
    @objc var contentType: AWKGalleryItemContentType {
        get {
            if let cachedContentType: AWKGalleryItemContentType = self.cachedContentType {
                return cachedContentType
            }
            var contentType: AWKGalleryItemContentType = AWKGalleryItemContentType.image
            if let contentURL: URL = self.contentURL, self.animated == true {
                //The image is animated, check if it's a gif file or MP4 file
                let pathExtension: String? = self.animatedURLString?.pathExtension
                if pathExtension == "mp4" {
                    //The extension ends in MP4 so it's a MP4 for sure
                    contentType = AWKGalleryItemContentType.repeatingMovie
                } else if contentURL.absoluteString.contains("fm=mp4") == true {
                    //The URL has the reddit "format" query item. This means it's a MP4 file
                    contentType = AWKGalleryItemContentType.repeatingMovie
                } else if pathExtension == "gif" || pathExtension == "gif.png" {
                    //The path extenion is gif or the cherry mistake: gif.png. This means it's a gif file
                    contentType = AWKGalleryItemContentType.animatedImage
                }
                if contentType == AWKGalleryItemContentType.image && self.contentURL?.pathExtension == "gif" {
                    //if the content type is still not changed we check if the host is a reddit hosted gif. If it's reddit hosted it will have an MP4 URL
                    var isRedditHosted: Bool = false
                    let redditMediaHosts: [String] = ["redditmedia.com", "redd.it", "reddituploads.com"]
                    for host: String in redditMediaHosts {
                        if let URLHost: String = contentURL.host {
                            if URLHost.contains(host) {
                                isRedditHosted = true
                                break
                            }
                        }
                    }
                    
                    if isRedditHosted {
                        contentType = AWKGalleryItemContentType.repeatingMovie
                    }
                }
            }
            
            //If the type was not updated we will treat it as a regular image
            return contentType
        }
        set {
            
        }
    }
    
    @objc var placeholderImage: UIImage? {
        if let urlString = self.mediaObject?.thumbnailWithSize(UIScreen.main.bounds.size)?.urlString {
            return SDImageCache.shared().imageFromDiskCache(forKey: urlString)
        }
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
        return CGSize(width: CGFloat(self.mediaObject?.width?.floatValue ?? 0), height: CGFloat(self.mediaObject?.height?.floatValue ?? 0))
    }
    
    fileprivate var isAlbumItem: Bool {
        return (self.mediaObject?.content as? Post)?.mediaObjects?.count ?? 0 > 1
    }
    
    @objc var attributedTitle: NSAttributedString? {
        if let post = self.mediaObject?.content as? Post, let postTitle = post.title, !self.isAlbumItem {
            return NSAttributedString(string: postTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17)])
        } else if let imageTitle = self.mediaObject?.captionTitle, self.isAlbumItem {
            let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.paragraphSpacing = 4
            return NSAttributedString(string: imageTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17), NSAttributedStringKey.paragraphStyle: paragraphStyle])
        }
        return nil
    }
    
    @objc var attributedSubtitle: NSAttributedString? {
        if self.mediaObject?.captionTitle != nil || self.mediaObject?.captionDescription != nil {
            let content = NSMutableAttributedString()
            
            // Show the caption title in the subtitle for posts, as the post title is being shown in the title instead of the caption title
            if !self.isAlbumItem {
                
                if let captionTitle = self.mediaObject?.captionTitle {
                    
                    let titleString = NSAttributedString(string: captionTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote).pointSize, weight: UIFont.Weight.medium)])
                    content.append(titleString)
                }
                
                if self.mediaObject?.captionTitle != nil && self.mediaObject?.captionDescription != nil {
                    content.append(NSAttributedString(string: "\n\n"))
                }
                
            }
            
            if let captionDescription = self.mediaObject?.captionDescription {
                
                let subtitleString = NSAttributedString(string: captionDescription, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white.withAlphaComponent(0.8), NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote)])
                content.append(subtitleString)
            }
            
            return content
        }
        
        return nil
    }
    
}

func == (lhs: GalleryItem, rhs: GalleryItem) -> Bool {
    return lhs.contentURL == rhs.contentURL
}

extension Snoo.MediaObject {
    
    var galleryItem: GalleryItem {
        get {
            return GalleryItem(mediaObject: self)
        }
        set {
            // Don't do anything. It's already saved.
        }
    }
    
}
