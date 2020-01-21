//
//  MediaOverviewCollectionViewCell.swift
//  beam
//
//  Created by Robin Speijer on 12-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import SDWebImage
import Snoo

private let MediaOverviewCollectionViewCellEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

class MediaOverviewCollectionViewCell: BeamCollectionViewCell, MediaCellMediaLabels {
    
    var imageOperation: SDWebImageOperation?
    
    // MARK: - Properties
    @IBOutlet var mediaImageView: UIImageView!
    @IBOutlet fileprivate var captionLabel: UILabel!
    @IBOutlet var mediaLabelImageViews: [UIImageView]?
    
    @IBOutlet var albumStackUpperView: UIView?
    @IBOutlet var albumStackBottomView: UIView?
    
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
    
    @IBOutlet var imageTopConstraint: NSLayoutConstraint?
    @IBOutlet var imageAlbumTopConstraint: NSLayoutConstraint?
    
    @IBOutlet var imageViewOverlay: UIView?
    @IBOutlet var spoilerOverlay: UIVisualEffectView?
    
    override var isOpaque: Bool {
        didSet {
            if self.mediaImageView != nil {
                self.appearanceDidChange()
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.imageViewOverlay?.isHidden = !self.isHighlighted
        }
    }
    
    var mediaObject: Snoo.MediaObject? {
        didSet {
            self.imageOperation?.cancel()
            self.mediaImageView.image = nil
            self.fetchImage()
            self.setNeedsUpdateConstraints()
            self.appearanceDidChange()
            self.reloadAlbumIdicators()
            self.reloadSpoilerOverlay()
            self.reloadMediaLabels()
        }
    }
    
    func reloadSpoilerOverlay() {
        self.spoilerOverlay?.isHidden = !(self.contentIsNSFW && self.shouldShowNSFWOverlay) && !(self.contentIsSpoiler && self.shouldShowSpoilerOverlay)
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.mediaLabelImageViews?.forEach({ (imageView) in
            imageView.accessibilityIgnoresInvertColors = true
        })
        self.mediaImageView.accessibilityIgnoresInvertColors = true
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.contentView.isHidden = false
        self.mediaImageView.isHidden = false
        
        if self.mediaObject != nil {
            self.mediaObject = nil
        }
        self.imageOperation?.cancel()
    }
    
    deinit {
        self.imageOperation?.cancel()
    }
    
    // MARK: - Layout
    
    override func updateConstraints() {
        if let imageAlbumTopConstraint = self.imageAlbumTopConstraint {
             imageAlbumTopConstraint.isActive = self.representsAlbum
        }
        if let imageTopConstraint = self.imageTopConstraint {
            imageTopConstraint.isActive = !self.representsAlbum
        }
        super.updateConstraints()
    }
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        self.captionLabel?.attributedText = MediaOverviewCollectionViewCell.attributedContentForMediaObject(self.mediaObject)
        
        if self.albumStackBottomView != nil {
            switch self.userInterfaceStyle {
            case .dark:
                self.albumStackUpperView?.backgroundColor = UIColor.white
                self.albumStackBottomView?.backgroundColor = UIColor.white
            default:
                self.albumStackUpperView?.backgroundColor = UIColor.black
                self.albumStackUpperView?.backgroundColor = UIColor.black
            }
        }
        
        if !self.isOpaque {
            self.contentView.backgroundColor = UIColor.clear
            self.backgroundColor = UIColor.clear
        } else {
            self.contentView.backgroundColor = AppearanceValue(light: UIColor.white, dark: UIColor.beamDarkContentBackground)
            self.backgroundColor = AppearanceValue(light: UIColor.white, dark: UIColor.beamDarkContentBackground)
        }
        
        self.mediaImageView.isOpaque = self.isOpaque
        
        self.mediaImageView.backgroundColor = AppearanceValue(light: UIColor(red: 209 / 255, green: 208 / 255, blue: 212 / 255, alpha: 1.0), dark: UIColor(red: 56 / 255, green: 56 / 255, blue: 56 / 255, alpha: 1.0))
    }
    
    // MARK: - Content
    
    fileprivate var representsAlbum: Bool {
        return (self.mediaObject?.content?.mediaObjects?.count ?? 0) > 1
    }
    
    func reloadAlbumIdicators() {
        self.albumStackBottomView?.isHidden = !self.representsAlbum
        self.albumStackUpperView?.isHidden = !self.representsAlbum
    }
    
    fileprivate func fetchImage() {
        
        let thumbnail = self.mediaObject?.thumbnailWithSize(self.bounds.size)
        let urlString = thumbnail?.url?.absoluteString ?? self.mediaObject?.contentURL?.absoluteString
        if let urlString = urlString, let url = URL(string: urlString) {
            
            if let cachedImage = SDImageCache.shared.imageFromDiskCache(forKey: urlString) {
                self.mediaImageView.image = cachedImage
                self.reloadAlbumIdicators()
            } else {
                var options = DownscaledImageOptions()
                options.constrainingSize = self.mediaImageView.bounds.size
                options.contentMode = .scaleAspectFill
                
                self.imageOperation = AppDelegate.shared.imageLoader.startDownloadingImageWithURL(url, downscalingOptions: options, progressHandler: nil, completionHandler: { (image) in
                    if image != nil {
                        SDImageCache.shared.store(image, forKey: urlString, toDisk: true)
                    }
                    
                    DispatchQueue.main.async {
                        self.mediaImageView.image = image
                        self.imageOperation = nil
                        self.reloadAlbumIdicators()
                    }
                })
            }
        }
    }
    
    class func attributedContentForMediaObject(_ mediaObject: Snoo.MediaObject?) -> NSAttributedString? {
        var contentStrings = [NSAttributedString]()
        if let captionTitle = mediaObject?.captionTitle {
            let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.minimumLineHeight = 21
            paragraphStyle.maximumLineHeight = 21
            
            let string = NSAttributedString(string: captionTitle, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold), NSAttributedString.Key.foregroundColor: AppearanceValue(light: UIColor.black, dark: UIColor.white), NSAttributedString.Key.paragraphStyle: paragraphStyle])
            contentStrings.append(string)
        }
        if let captionDescription = mediaObject?.captionDescription {
            let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.minimumLineHeight = 26
            paragraphStyle.maximumLineHeight = 26
            
            let string = NSAttributedString(string: captionDescription, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: AppearanceValue(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.8), NSAttributedString.Key.paragraphStyle: paragraphStyle])
            contentStrings.append(string)
        }
        
        guard contentStrings.count > 0 else {
            return nil
        }
        
        if contentStrings.count == 2 {
            contentStrings.insert(NSAttributedString(string: "\n"), at: 1)
        }
        
        let content = NSMutableAttributedString()
        for string in contentStrings {
            content.append(string)
        }
        
        return content
    }
    
    class func heightForMetaData(_ metadata: NSAttributedString, constrainingSize: CGSize) -> CGFloat {
        let contentConstrainingRect = CGRect(origin: CGPoint.zero, size: constrainingSize).inset(by: MediaOverviewCollectionViewCellEdgeInsets)
        let contentSize = metadata.boundingRect(with: contentConstrainingRect.size, options: [NSStringDrawingOptions.usesFontLeading, NSStringDrawingOptions.usesLineFragmentOrigin], context: nil).size
        return contentSize.height
    }
    
}
