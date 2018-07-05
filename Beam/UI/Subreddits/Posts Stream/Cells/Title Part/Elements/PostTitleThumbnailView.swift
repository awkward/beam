//
//  PostTitleThumbnailView.swift
//  Beam
//
//  Created by Rens Verhoeven on 11-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CherryKit
import SDWebImage

final class PostTitleThumbnailView: BeamControl, MediaImageLoader, MediaCellMediaLabels {
    
    var post: Post? {
        didSet {
            if self.post != oldValue {
                self.mediaObject = self.post?.mediaObjects?.firstObject as? MediaObject
                self.reloadSpoilerOverlay()
                self.startImageLoading()
                self.reloadMediaLabels()
                self.setNeedsLayout()
            }
        }
    }
    
    var mediaObject: MediaObject?
    var mediaImageView: UIImageView!
    var imageOperation: SDWebImageOperation?
    var preferredThumbnailSize: CGSize {
        return CGSize(width: 70, height: 70)
    }
    
    var contentIsVideo: Bool {
        if let URLString = self.post?.urlString, let URL = URL(string: URLString), URL.estimatedURLType == URLType.video {
            return true
        }
        return false
    }
    
    func mediaURLString() -> String? {
        guard self.post != nil else {
            return nil
        }
        if self.contentIsVideo == true {
            if let URLString = self.post?.urlString, let URL = URL(string: URLString), let youTubeVideoID = URL.youTubeVideoID {
                return "https://img.youtube.com/vi/\(youTubeVideoID)/mqdefault.jpg"
            }
            return nil
        } else {
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
    }
    
    var shouldShowNSFWOverlay: Bool = true {
        didSet {
            self.reloadSpoilerOverlay()
        }
    }
    var shouldShowSpoilerOverlay: Bool = true {
        didSet {
            self.reloadSpoilerOverlay()
        }
    }
    
    var spoilerOverlay: UIVisualEffectView?
    
    var mediaLabelImageViews: [UIImageView]? = [UIImageView]()
    
    func imageLoadingCompleted() {
        //Required function but is actually not needed
    }
    
    func progressDidChange(_ progress: CGFloat) {
        //Required function but is actually not needed
    }
    
    func reloadSpoilerOverlay() {
        if (self.contentIsNSFW && self.shouldShowNSFWOverlay) || (self.contentIsSpoiler && self.shouldShowSpoilerOverlay) {
            if self.spoilerOverlay == nil && (self.contentIsNSFW || self.contentIsSpoiler) {
                self.spoilerOverlay = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
                self.spoilerOverlay!.layer.cornerRadius = self.layer.cornerRadius
                self.spoilerOverlay!.clipsToBounds = true
                self.spoilerOverlay?.isUserInteractionEnabled = false
                self.addSubview(self.spoilerOverlay!)
            }
            self.spoilerOverlay!.isHidden = false
        } else {
            self.spoilerOverlay?.isHidden = true
        }
    }
    
    var useSmallMediaLabels: Bool {
        return true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    func prepareForReuse() {
        self.stopImageLoading()
        self.post = nil
        self.mediaImageView.image = nil
    }
    
    fileprivate func setupView() {
        let cornerRadius: CGFloat = 3
        
        self.isOpaque = true
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
        
        self.mediaImageView = UIImageView()
        self.mediaImageView.accessibilityIgnoresInvertColors = true
        self.mediaImageView.contentMode = UIViewContentMode.scaleAspectFill
        self.addSubview(self.mediaImageView)
        
        self.mediaImageView.isOpaque = true
        self.mediaImageView.layer.cornerRadius = cornerRadius
        self.mediaImageView.clipsToBounds = true
        
        self.mediaLabelImageViews?.append(UIImageView())
        self.mediaLabelImageViews?.append(UIImageView())
        self.mediaLabelImageViews?.append(UIImageView())
        self.mediaLabelImageViews?.forEach({ (imageView) in
            imageView.accessibilityIgnoresInvertColors = true
        })
        
    }
    
    class func shouldShowThumbnailForPost(_ post: Post?) -> Bool {
        if let URLString = post?.urlString, let URL = URL(string: URLString), URL.estimatedURLType == URLType.video {
            return true
        }
        if let mediaObjects = post?.mediaObjects, mediaObjects.count > 0 {
            return true
        }
        return false
    }
    
    override func draw(_ rect: CGRect) {
        if let mediaObjects = self.post?.mediaObjects, mediaObjects.count > 1 {
            let backgroundAlbumStackPath = UIBezierPath(roundedRect: CGRect(x: 10, y: 0, width: self.bounds.width - 20, height: 2), byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight], cornerRadii: CGSize(width: 1, height: 1))
            DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.4).setFill()
            backgroundAlbumStackPath.fill()
            
            let middleAlbumStackPath = UIBezierPath(roundedRect: CGRect(x: 5, y: 3, width: self.bounds.width - 10, height: 2), byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight], cornerRadii: CGSize(width: 1, height: 1))
            DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.6).setFill()
            middleAlbumStackPath.fill()
        }
    }
    
    // MARK: Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let mediaObjects = self.post?.mediaObjects, mediaObjects.count > 1 {
            //Adjust the layoutMargins for the media labels
            self.layoutMargins = UIEdgeInsets(top: 6 + 5, left: 5, bottom: 5, right: 5)
            self.mediaImageView.frame = CGRect(x: 0, y: 6, width: self.bounds.width, height: self.bounds.height - 6)
        } else {
            self.mediaImageView.frame = self.bounds
            self.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        }
        self.spoilerOverlay?.frame = self.mediaImageView.frame
        
        self.setNeedsDisplay()
        
        self.layoutMediaLabels(self)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.mediaImageView.isOpaque = true
        self.mediaImageView.backgroundColor = DisplayModeValue(UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1), darkValue: UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1))
        
        self.setNeedsDisplay()
    }
    
    // MARK: Sizing

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 70, height: 70)
    }
}
