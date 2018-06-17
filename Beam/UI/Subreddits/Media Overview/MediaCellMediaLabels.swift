//
//  MediaCellMediaLabels.swift
//  Beam
//
//  Created by Rens Verhoeven on 16-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

protocol MediaCellMediaLabels {
    
    var mediaObject: MediaObject? { get set }
    var mediaImageView: UIImageView! { get }
    
    var mediaLabelImageViews: [UIImageView]? { get set }
    
    var contentIsNSFW: Bool { get}
    var contentIsAnimated: Bool { get }
    var contentIsSpoiler: Bool { get }
    var contentIsVideo: Bool { get }
    
    var useSmallMediaLabels: Bool { get }
    
    func reloadMediaLabels()
    
    func layoutMediaLabels(_ superView: UIView)
    
}

extension MediaCellMediaLabels {
    
    // MARK: - Media label
    
    func reloadMediaLabels() {
        if let mediaLabelImageViews = self.mediaLabelImageViews {
            var labels: [UIImage] = [UIImage]()
            if self.contentIsNSFW {
                labels.append(UIImage(named: "media-nsfw-label\(self.useSmallMediaLabels ? "-small" : "")", in: nil, compatibleWith: nil)!)
            }
            if self.contentIsSpoiler {
                labels.append(UIImage(named: "media-spoiler-label\(self.useSmallMediaLabels ? "-small" : "")", in: nil, compatibleWith: nil)!)
            }
            if self.contentIsAnimated {
                labels.append(UIImage(named: "media-gif-label\(self.useSmallMediaLabels ? "-small" : "")", in: nil, compatibleWith: nil)!)
            }
            if self.contentIsVideo {
                labels.append(UIImage(named: "media-video-label\(self.useSmallMediaLabels ? "-small" : "")", in: nil, compatibleWith: nil)!)
            }
            
            var index: Int = 0
            for imageView: UIImageView in mediaLabelImageViews {
                if imageView.tintColor != UIColor.white {
                    imageView.tintColor = UIColor.white
                }
                if index >= labels.count {
                    imageView.image = nil
                } else {
                    let labelImage: UIImage = labels[index]
                    imageView.image = labelImage
                }
                index += 1
            }
        }
    }
    
    func layoutMediaLabels(_ superView: UIView) {
        if let imageViews = self.mediaLabelImageViews {
            for imageView in imageViews {
                if imageView.superview != superView {
                    superView.addSubview(imageView)
                } else {
                    superView.bringSubview(toFront: imageView)
                }
                
            }
            let spacing: CGFloat = 4
            var xPosition = superView.bounds.width - superView.layoutMargins.right
            let yPosition = superView.bounds.minX + superView.layoutMargins.top
            for imageView in imageViews {
                if imageView.image != nil {
                    imageView.isHidden = false
                    let size = imageView.image?.size ?? CGSize()
                    xPosition -= size.width
                    imageView.frame = CGRect(origin: CGPoint(x: xPosition, y: yPosition), size: size)
                    xPosition -= spacing
                } else {
                    imageView.isHidden = true
                }
                
            }
        }
        
    }
    
    var useSmallMediaLabels: Bool {
        return false
    }
    
    // MARK: - Content flags
    
    var contentIsNSFW: Bool {
        if let galleryItem = self.mediaObject?.galleryItem {
            return (galleryItem.nsfw == true || (self.mediaObject?.content as? Post)?.isContentNSFW == true)
        }
        return false
    }
    
    var contentIsAnimated: Bool {
        if let galleryItem = self.mediaObject?.galleryItem {
            return galleryItem.animated == true
        }
        return false
    }
    
    var contentIsSpoiler: Bool {
        return  (self.mediaObject?.content as? Post)?.isContentSpoiler == true
    }
    
    var contentIsVideo: Bool {
        return false
    }
}
