//
//  CommentLinkPreviewView.swift
//  Beam
//
//  Created by Rens Verhoeven on 26/01/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit
import CherryKit
import Snoo
import Ocarina

class CommentLinkPreviewView: BeamControl {
    
    var comment: Comment?
    
    var link: URL? {
        didSet {
            guard self.link != oldValue else {
                return
            }
            self.urlInformation = nil
            self.isLoading = false
            self.request?.cancel()
            self.imageMetadataTask?.cancel()
            self.reloadDomainName()
            guard let token = AppDelegate.shared.cherryController.accessToken, let link = self.link, let comment = self.comment, let identifier = comment.identifier  else {
                return
            }
            guard comment.mediaObjects == nil || comment.mediaObjects!.count <= 0 else {
                self.reloadContents()
                return
            }
            
            self.isLoading = true
            DispatchQueue.global(qos: .userInteractive).async(execute: { [weak self] () -> Void in
                guard self?.link == link else {
                    return
                }
                
                if self?.isCherryAcceptedImageLink(link) == true {
                    self?.startImageMetadataRequest(with: link, identifier: identifier, cherryToken: token)
                } else {
                    self?.startUrlMetadataRequest(with: link)
                }
            })
            
        }
    }
    
    private func startUrlMetadataRequest(with link: URL) {
        self.request = link.oca.fetchInformation { (information, error) in
            DispatchQueue.main.async { [weak self] in
                self?.urlInformation = information
                self?.isLoading = false
                //Ignore cancel errors
                if let error = error as NSError?, !(error.code == NSURLErrorCancelled && error.domain == NSURLErrorDomain) {
                    NSLog("Error while fetching URL metadata: \(error)")
                }
            }
        }
    }
    
    private func startImageMetadataRequest(with link: URL, identifier: String, cherryToken: String) {
        let imageMetadataRequest = ImageRequest(postID: identifier, imageURL: link.absoluteString)
        self.imageMetadataTask = ImageMetadataTask(token: cherryToken, imageRequests: [imageMetadataRequest])
        self.imageMetadataTask?.start({ (result: TaskResult) -> Void in
            DispatchQueue.main.async { [weak self] in
                if let result = result as? ImageMetadataTaskResult, let imageResponse = result.metadata.first, let comment = self?.comment {
                    AppDelegate.shared.managedObjectContext.performAndWait {
                        comment.insertMediaObjects(with: imageResponse)
                    }
                    self?.reloadContents()
                    self?.isLoading = false
                } else {
                    self?.reloadContents()
                    self?.isLoading = false
                    
                    //Ignore cancel errors
                    if let error = result.error as NSError?, !(error.code == NSURLErrorCancelled && error.domain == NSURLErrorDomain) {
                        NSLog("Error while fetching URL metadata: \(error)")
                        
                    }
                }
            }
        })
    }
    
    private func isCherryAcceptedImageLink(_ link: URL) -> Bool {
        guard let imageUrlPatterns = AppDelegate.shared.cherryController.features?.imageURLPatterns else {
            return false
        }
        var isImageLink = false
        for pattern in imageUrlPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpression.Options.caseInsensitive])
                guard let match = regex.firstMatch(in: link.absoluteString, options: [], range: NSRange(location: 0, length: (link.absoluteString as NSString).length)), match.numberOfRanges > 0 else {
                    continue
                }
                isImageLink = true
                break
            } catch {
                NSLog("Invalid image URL regular expression \(error)")
            }
        }
        return isImageLink
    }
    
    var isLoading = false
    
    lazy fileprivate var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isOpaque = true
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    lazy fileprivate var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        label.isOpaque = true
        return label
    }()
    lazy fileprivate var domainLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 11)
        label.isOpaque = true
        return label
    }()
    
    fileprivate var urlInformation: URLInformation? {
        didSet {
            self.reloadContents()
        }
    }
    
    fileprivate var request: OcarinaInformationRequest?
    fileprivate var imageMetadataTask: ImageMetadataTask?
    
    fileprivate func reloadContents() {
        self.thumbnailImageView.sd_cancelCurrentImageLoad()
        if let information = self.urlInformation {
            //URL with metadata
            self.thumbnailImageView.isHidden = information.imageURL == nil
            if let imageUrl = information.imageURL {
                self.thumbnailImageView.sd_setImage(with: imageUrl)
            } else {
                self.thumbnailImageView.image = nil
            }
            
            self.titleLabel.isHidden = information.title == nil || information.title!.count <= 0
            self.titleLabel.text = information.title
        } else if let mediaObjects = self.comment?.mediaObjects?.array as? [MediaObject], let mediaObject = mediaObjects.first {
            //Album or single image
            let isAlbum = mediaObjects.count > 1
            
            self.titleLabel.isHidden = false
            if isAlbum {
                self.titleLabel.text = "Tap to view album"
            } else {
                self.titleLabel.text = "Tap to view image"
                if let title = mediaObject.captionTitle, title.count > 0 {
                    self.titleLabel.text = title
                }
            }
            
            if let thumbnailUrlString = mediaObject.thumbnailWithSize(self.thumbnailImageView.bounds.size)?.urlString, let imageUrl = URL(string: thumbnailUrlString) {
                self.thumbnailImageView.isHidden = false
                self.thumbnailImageView.sd_setImage(with: imageUrl)
            } else {
                self.thumbnailImageView.isHidden = true
                self.thumbnailImageView.image = nil
            }
            
        } else {
            //Nothing
            self.titleLabel.isHidden = true
            self.titleLabel.text = nil
            
            self.thumbnailImageView.isHidden = true
            self.thumbnailImageView.image = nil
        }
        
        self.reloadDomainName()
        
        self.displayModeDidChange()
        self.setNeedsLayout()
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.displayModeDidChange()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.displayModeDidChange()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupView()
    }
    
    private func setupView() {
        self.layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        self.layer.cornerRadius = 3
        self.layer.masksToBounds = true
        self.layer.borderWidth = 0.5
        self.isOpaque = true
        
        self.addSubview(self.thumbnailImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.domainLabel)
        
    }
    
    private func reloadDomainName() {
        self.domainLabel.text = self.link?.host?.stringByRemovingStrings(["www."])
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.titleLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        
        var containerBackgroundColor = DisplayModeValue(UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0), darkValue: UIColor(red: 38 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1.0))
        if self.isHighlighted || self.isSelected {
            containerBackgroundColor = DisplayModeValue(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1), darkValue: UIColor(red: 0.23, green: 0.23, blue: 0.23, alpha: 1))
        }
        self.backgroundColor = containerBackgroundColor
        self.thumbnailImageView.backgroundColor = containerBackgroundColor
        self.titleLabel.backgroundColor = containerBackgroundColor
        self.domainLabel.backgroundColor = containerBackgroundColor
        
        let borderColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
        
        self.layer.borderColor = borderColor.cgColor
        self.domainLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
    }
    
    // MARK: - Layout
    
    //We want to keep the performance as high as possible in the comments, therefore we use layoutSubviews instead of Auto layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let hasImage = !self.thumbnailImageView.isHidden
        let hasTitle = !self.titleLabel.isHidden
        
        var x = self.layoutMargins.left
        var y = self.layoutMargins.top
        let spacing: CGFloat = 10
        
        if hasImage {
            let imageHeight = self.bounds.height - self.layoutMargins.top - self.layoutMargins.bottom
            let imageViewFrame = CGRect(x: x, y: y, width: imageHeight, height: imageHeight)
            self.thumbnailImageView.frame = imageViewFrame
            
            x = imageHeight + spacing
        }
        
        if hasTitle {
            //We show the title and the domain
            let maxWidth = self.bounds.width - x - self.layoutMargins.right
            let maxHeight = self.bounds.height - self.layoutMargins.top - self.layoutMargins.bottom
            let maxSize = CGSize(width: maxWidth, height: maxHeight / 2)
            
            self.titleLabel.preferredMaxLayoutWidth = maxWidth
            self.domainLabel.preferredMaxLayoutWidth = maxWidth
            
            var titleLabelSize = self.titleLabel.sizeThatFits(maxSize)
            titleLabelSize.width = min(titleLabelSize.width, maxWidth)
            var domainLabelSize = self.domainLabel.sizeThatFits(maxSize)
            domainLabelSize.width = min(domainLabelSize.width, maxWidth)
            
            y = (self.bounds.height - (titleLabelSize.height + domainLabelSize.height + 2)) / 2
            
            self.titleLabel.frame = CGRect(origin: CGPoint(x: x, y: y), size: titleLabelSize)
            y += titleLabelSize.height
            y += 2
            
            self.domainLabel.frame = CGRect(origin: CGPoint(x: x, y: y), size: domainLabelSize)
        } else {
            //We only show the domain of the URL
            let maxWidth = self.bounds.width - x - self.layoutMargins.right
            let maxHeight = self.bounds.height - self.layoutMargins.top - self.layoutMargins.bottom
            let maxSize = CGSize(width: maxWidth, height: maxHeight)
            
            self.domainLabel.preferredMaxLayoutWidth = maxWidth
            
            let domainLabelSize = self.domainLabel.sizeThatFits(maxSize)
            
            y = (self.bounds.height - (domainLabelSize.height)) / 2
            
            self.domainLabel.frame = CGRect(origin: CGPoint(x: x, y: y), size: domainLabelSize)
        }
        
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 50)
    }
    
}
