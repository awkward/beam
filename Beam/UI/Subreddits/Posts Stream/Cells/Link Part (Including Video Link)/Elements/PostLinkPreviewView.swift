//
//  PostLinkPreviewView.swift
//  Beam
//
//  Created by Rens Verhoeven on 09/02/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit
import CherryKit
import Snoo
import Ocarina

@IBDesignable
final class PostLinkPreviewView: BeamControl {

    @IBInspectable var isVideoPreview: Bool = false {
        didSet {
            if self.isVideoPreview {
                self.loadingPlaceholderImageView.image = #imageLiteral(resourceName: "empty_video_link_placeholder")
            } else {
                self.loadingPlaceholderImageView.image = #imageLiteral(resourceName: "empty_link_placeholder")
            }
            
            self.playIconImageView.isHidden = !self.isVideoPreview
            
            self.setNeedsLayout()
            self.invalidateIntrinsicContentSize()
        }
    }
    @IBInspectable var showsURLDescription: Bool = true {
        didSet {
            self.displayModeDidChange()
            self.setNeedsLayout()
        }
    }
    
    fileprivate var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.isOpaque = true
        imageView.clipsToBounds = true
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }()
    fileprivate var playIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.center
        imageView.isOpaque = false
        imageView.clipsToBounds = true
        imageView.image = #imageLiteral(resourceName: "video_play_external")
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }()
    fileprivate var loadingPlaceholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.scaleToFill
        imageView.isOpaque = true
        imageView.clipsToBounds = true
        imageView.image = #imageLiteral(resourceName: "empty_link_placeholder")
        return imageView
    }()
    fileprivate var spoilerBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.center
        imageView.isOpaque = true
        imageView.clipsToBounds = true
        imageView.image = #imageLiteral(resourceName: "media-nsfw-label")
        imageView.accessibilityIgnoresInvertColors = false
        return imageView
    }()
    
    fileprivate var titleLabel: UILabel = {
        let label = UILabel()
        label.font = PostLinkPreviewView.titleFont
        label.isOpaque = true
        label.numberOfLines = 2
        return label
    }()
    fileprivate var domainLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.isOpaque = true
        label.numberOfLines = 1
        return label
    }()
    
    fileprivate var post: Post?
    fileprivate var link: URL?

    fileprivate var allowSpoiler: Bool = false
    fileprivate var allowNSFW: Bool = false
    
    fileprivate var isLoading: Bool = false {
        didSet {
            self.loadingPlaceholderImageView.isHidden = !self.isLoading
            self.titleLabel.isHidden = self.isLoading
            self.domainLabel.isHidden = self.isLoading
        }
    }
    
    fileprivate var information: URLInformation? {
        didSet {
            self.reloadContents()
            self.displayModeDidChange()
            self.setNeedsLayout()
        }
    }
    
    fileprivate var request: OcarinaInformationRequest?
    
    //Generating the UIFont everytime displayModeDidChange is called seems to cause some CPU time so that's why I'm saving it.
    fileprivate static let titleFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
    fileprivate static let subtitleFont = UIFont.systemFont(ofSize: 12)
    
    fileprivate var attributedTitle: NSAttributedString? {
        guard let post = self.post, !post.isContentSpoiler.boolValue || self.allowSpoiler else {
            //If the post is marked as a spoiler, we don't show the title and description
            return nil
        }
        let titleAttributes = [NSAttributedStringKey.font: PostLinkPreviewView.titleFont, NSAttributedStringKey.foregroundColor: self.displayMode == .dark ? UIColor.white: UIColor.beamGreyExtraDark()]
        let descriptionAttributes = [NSAttributedStringKey.font: PostLinkPreviewView.subtitleFont, NSAttributedStringKey.foregroundColor: self.displayMode == .dark ? UIColor.beamGrey() : UIColor(red: 0.58, green: 0.58, blue: 0.58, alpha: 1)]
        let isImgurLink = post.urlString?.contains("imgur.com") == true
        
        let string = NSMutableAttributedString()
        if let metadata = self.information {
            let hasTitle = metadata.title?.count ?? 0 > 0
            let hasDescription = metadata.descriptionText?.count ?? 0 > 0
            
            if hasTitle, let title = metadata.title {
                string.append(NSAttributedString(string: title, attributes: titleAttributes))
            } else if isImgurLink {
                string.append(NSAttributedString(string: AWKLocalizedString("tap-to-view-imgur"), attributes: titleAttributes))
            }
            
            if hasTitle && hasDescription && self.showsURLDescription {
                string.append(NSAttributedString(string: " - ", attributes: descriptionAttributes))
            }
            
            if hasDescription && self.showsURLDescription, let description = metadata.descriptionText {
                string.append(NSAttributedString(string: description, attributes: descriptionAttributes))
            }
        } else if isImgurLink {
            string.append(NSAttributedString(string: AWKLocalizedString("tap-to-view-imgur"), attributes: titleAttributes))
        } else {
            if let urlString = self.post?.urlString {
                string.append(NSAttributedString(string: urlString, attributes: descriptionAttributes))
            }
        }
        
        return string
    }
    
    fileprivate var shouldLoadImagePreview: Bool {
        guard self.post?.isContentSpoiler.boolValue == false || self.allowSpoiler else {
            return false
        }
        guard self.post?.isContentNSFW.boolValue == false || self.allowNSFW else {
            return false
        }
        return self.shouldShowImagePreview
    }
    
    /// If the image preview view should show, if there is a spoiler or NSFW it should show, but not load the image!
    fileprivate var shouldShowImagePreview: Bool {
        if self.isVideoPreview {
            return true
        }
        guard self.post?.isContentSpoiler.boolValue == false || self.allowSpoiler else {
            return true
        }
        guard self.post?.isContentNSFW.boolValue == false || self.allowNSFW else {
            return true
        }
        return self.information?.imageURL != nil
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupView()
    }
    
    fileprivate func setupView() {
        self.isOpaque = true
        
        self.layer.cornerRadius = 3
        self.layer.masksToBounds = true
        self.layer.borderWidth = 0.5
        
        self.addSubview(self.previewImageView)
        self.addSubview(self.playIconImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.domainLabel)
        self.addSubview(self.loadingPlaceholderImageView)
        self.addSubview(self.spoilerBadgeImageView)
        
        self.previewImageView.isHidden = true
        self.playIconImageView.isHidden = true
        self.titleLabel.isHidden = true
        self.domainLabel.isHidden = true
        self.spoilerBadgeImageView.isHidden = true
    }
    
    func changeLink(link: URL?, post: Post?, allowNSFW: Bool = false, allowSpoiler: Bool = false) {
        guard self.link != link || self.post != post || self.allowNSFW != allowNSFW || self.allowSpoiler != allowSpoiler else {
            return
        }
        self.unscheduleFetchingMetadata()
        self.cancelAllRequests()
        self.information = nil
        self.isLoading = true
        
        if let link = link, link.estimatedURLType == URLType.video && !self.isVideoPreview {
            NSLog("Loading a video URL (\(link)) into a none video link preview might not yield the best result")
        } else if let link = link, link.estimatedURLType != URLType.video && self.isVideoPreview {
            NSLog("Loading a URL (\(link)) into a video link preview might not yield the best result")
        }
        self.allowNSFW = allowNSFW
        self.allowSpoiler = allowSpoiler
        self.post = post
        self.link = link
        
        if let link = link, let cachedInformation = OcarinaManager.shared.cache[link] {
            self.information = cachedInformation
            self.doneLoading(animated: false)
        } else {
            self.reloadSpoilerBadge()
            self.reloadDomainName()
            self.scheduleFetchingMetadata()
        }
        
        self.setNeedsLayout()
    }
    
    fileprivate func reloadContents() {
        self.previewImageView.isHidden = !self.shouldShowImagePreview
        self.previewImageView.image = nil
        
        self.reloadDomainName()
        self.reloadSpoilerBadge()
        
        self.displayModeDidChange()
        
        self.setNeedsLayout()
        
        if self.shouldLoadImagePreview, let imageURL = self.information?.imageURL {
            self.previewImageView.sd_setImage(with: imageURL, completed: { (image, _, _, _) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.doneLoading(animated: true)
                    self.previewImageView.image = image
                })
                
            })
            self.updateConstraints()
            self.setNeedsLayout()
        } else {
            self.doneLoading(animated: true)
        }
    }
    
    fileprivate func reloadSpoilerBadge() {
        if self.post?.isContentSpoiler.boolValue == true && !self.allowSpoiler {
            self.spoilerBadgeImageView.isHidden = false
            self.spoilerBadgeImageView.image = self.isVideoPreview ? #imageLiteral(resourceName: "media-spoiler-label") : #imageLiteral(resourceName: "media-spoiler-label-small")
        } else if self.post?.isContentNSFW.boolValue == true && !self.allowNSFW {
            self.spoilerBadgeImageView.isHidden = false
            self.spoilerBadgeImageView.image = self.isVideoPreview ? #imageLiteral(resourceName: "media-nsfw-label") : #imageLiteral(resourceName: "media-nsfw-label-small")
        } else {
            self.spoilerBadgeImageView.isHidden = true
        }
    }
    
    fileprivate func reloadDomainName() {
        if let host = self.link?.host {
            let domain = host.stringByRemovingStrings(["www.", "www2."])
            self.domainLabel.text = domain
        } else {
            self.domainLabel.text = nil
        }
    }
    
    private func doneLoading(animated: Bool = true) {
        let oldValue = self.isLoading
        self.isLoading = false
        if animated && oldValue == false {
            self.loadingPlaceholderImageView.isHidden = false
            self.titleLabel.alpha = 0.0
            self.domainLabel.alpha = 0.0
            self.previewImageView.alpha = 0.0
            
            UIView.animate(withDuration: 0.32, animations: {
                self.loadingPlaceholderImageView.alpha = 0.0
                self.titleLabel.alpha = 1.0
                self.domainLabel.alpha = 1.0
                self.previewImageView.alpha = 1.0
            }, completion: { (_) in
                self.loadingPlaceholderImageView.isHidden = !self.isLoading
                self.loadingPlaceholderImageView.alpha = 1.0
            })
        }
    }
    
    // MARK: - Metadata loading
    
    fileprivate var requestDelay: TimeInterval = 0.5
    
    /// To prevent needlessly fetching metadata, we use a timeout to wait until we are really going to fetch that metadata.
    fileprivate var metadataFetchTimer: Timer?
    
    /// To prevent needlessly fetching metadata, we schedule fetching metadata till we are more certain that it has some value to do so.
    fileprivate func scheduleFetchingMetadata() {
        self.metadataFetchTimer?.invalidate()
        self.metadataFetchTimer = Timer.scheduledTimer(timeInterval: self.requestDelay, target: self, selector: #selector(startFetchingMetadata), userInfo: nil, repeats: false)
    }
    
    fileprivate func unscheduleFetchingMetadata() {
        self.metadataFetchTimer?.invalidate()
        self.metadataFetchTimer = nil
    }
    
    /// Directly start fetching metadata. Use scheduleFetchingMetadata instead, to prevent needlessly fetching metadata.
    @objc fileprivate func startFetchingMetadata() {
        self.unscheduleFetchingMetadata()
        
        self.cancelAllRequests()
        
        if let link = self.link {
            let request = link.oca.fetchInformation(completionHandler: { [weak self] (information, _) in
                DispatchQueue.main.async {
                    self?.information = information
                }
            })
            self.request = request
        } else {
            // Cant fetch URL
            self.information = nil
            self.isLoading = false
            self.cancelAllRequests()
        }
    }
    
    fileprivate func cancelAllRequests() {
        self.unscheduleFetchingMetadata()
        self.request?.cancel()
        self.request = nil
        self.doneLoading(animated: false)
        self.previewImageView.sd_cancelCurrentImageLoad()
    }
    
    // MARK: - Colors
    
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
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.titleLabel.attributedText = self.attributedTitle
        
        var backgroundColor = DisplayModeValue(UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0), darkValue: UIColor(red: 38 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1.0))
        if self.isHighlighted || self.isSelected {
            backgroundColor = DisplayModeValue(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1), darkValue: UIColor(red: 0.23, green: 0.23, blue: 0.23, alpha: 1))
        }
        self.backgroundColor = backgroundColor
        self.titleLabel.backgroundColor = backgroundColor
        self.domainLabel.backgroundColor = backgroundColor
        self.loadingPlaceholderImageView.backgroundColor = backgroundColor
        
        //The color used for the border, loading placeholder and empty imageView
        let secondColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
        self.previewImageView.backgroundColor = secondColor
        self.layer.borderColor = secondColor.cgColor
        //Setting the tintColor when it's already the correct tintColor causes the image to be tinted again, this leads to high CPU usage
        if self.loadingPlaceholderImageView.tintColor != secondColor {
            self.loadingPlaceholderImageView.tintColor = secondColor
        }
        
        self.domainLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        //Setting the tintColor when it's already the correct tintColor causes the image to be tinted again, this leads to high CPU usage
        if self.playIconImageView.tintColor != UIColor.white {
            self.playIconImageView.tintColor = UIColor.white
        }
        
        let badgeTintColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        if self.spoilerBadgeImageView.tintColor != badgeTintColor {
            self.spoilerBadgeImageView.tintColor = badgeTintColor
        }
        
    }
    
    // MARK: - Layout
    
    private let videoRatio: CGFloat = 16 / 9
    private let viewInsetsLink = UIEdgeInsets(top: 9, left: 9, bottom: 9, right: 9)
    private let viewInsetsVideo = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.isVideoPreview {
            self.previewImageView.layer.cornerRadius = 0
        } else {
            self.previewImageView.layer.cornerRadius = 2
        }
        self.previewImageView.layer.masksToBounds = true
        
        if self.isVideoPreview {
            self.layoutForVideoPreview()
        } else {
            self.layoutForLinkPreview()
        }
    }
    
    private func layoutForVideoPreview() {
        //First, layout the image
        let imageHeight = self.bounds.width / self.videoRatio
        let imageFrame = CGRect(x: 0, y: 0, width: self.bounds.width, height: imageHeight)
        self.previewImageView.frame = imageFrame
        self.playIconImageView.frame = imageFrame
        
        if !self.spoilerBadgeImageView.isHidden, let image = self.spoilerBadgeImageView.image {
            //Add the badge on top of the image view
            let badgeSize = image.size
            let badgeFrame = CGRect(x: self.bounds.width - self.viewInsetsVideo.right - badgeSize.width, y: self.viewInsetsVideo.top, width: badgeSize.width, height: badgeSize.height)
            self.spoilerBadgeImageView.frame = badgeFrame
        }
        
        var insets = self.viewInsetsVideo
        insets.top += imageHeight
        
        let titleToDomainSpacing: CGFloat = 4
        
        let descriptionRect = UIEdgeInsetsInsetRect(self.bounds, insets)
        var maxSize = descriptionRect.size
        
        var placeholderFrame = descriptionRect
        placeholderFrame.size.height = self.loadingPlaceholderImageView.image?.size.height ?? 0
        self.loadingPlaceholderImageView.frame = placeholderFrame
        
        self.domainLabel.preferredMaxLayoutWidth = maxSize.width
        var domainSize = self.domainLabel.sizeThatFits(maxSize)
        domainSize.width = min(domainSize.width, descriptionRect.width)
        
        guard self.titleLabel.attributedText != nil else {
            var yPosition = (descriptionRect.height - domainSize.height) / 2
            yPosition += insets.top
            
            self.domainLabel.frame = CGRect(origin: CGPoint(x: insets.left, y: yPosition), size: domainSize)
            return
        }
        
        maxSize.height -= domainSize.height
        maxSize.height -= titleToDomainSpacing
        
        self.titleLabel.preferredMaxLayoutWidth = maxSize.width
        var titleSize = self.titleLabel.sizeThatFits(maxSize)
        titleSize.width = min(titleSize.width, descriptionRect.width)
        let combinedHeight = titleSize.height + domainSize.height + titleToDomainSpacing
        var yPosition = (descriptionRect.height - combinedHeight) / 2
        yPosition += insets.top
        
        self.titleLabel.frame = CGRect(origin: CGPoint(x: insets.left, y: yPosition), size: titleSize)
        yPosition += titleSize.height
        yPosition += titleToDomainSpacing
        
        self.domainLabel.frame = CGRect(origin: CGPoint(x: insets.left, y: yPosition), size: domainSize)
        
    }
    
    private func layoutForLinkPreview() {
        var insets = self.viewInsetsLink
        
        let imageToTitleSpacing: CGFloat = 10
        let titleToDomainSpacing: CGFloat = 4
        
        var xPosition = insets.left
        if !self.previewImageView.isHidden {
            //First, layout the image
            let imageHeight = self.bounds.height - insets.top - insets.bottom
            let imageFrame = CGRect(x: xPosition, y: insets.top, width: imageHeight, height: imageHeight)
            self.previewImageView.frame = imageFrame
            
            xPosition += imageHeight
            xPosition += imageToTitleSpacing
            
            if !self.spoilerBadgeImageView.isHidden {
                //Add the badge on top of the image view
                self.spoilerBadgeImageView.frame = imageFrame
            }
        }
        
        insets.left = xPosition
        
        let descriptionRect = UIEdgeInsetsInsetRect(self.bounds, insets)
        var maxSize = descriptionRect.size
        
        var placeholderFrame = UIEdgeInsetsInsetRect(self.bounds, self.viewInsetsLink)
        placeholderFrame.size.height = self.loadingPlaceholderImageView.image?.size.height ?? 0
        self.loadingPlaceholderImageView.frame = placeholderFrame
        
        self.domainLabel.preferredMaxLayoutWidth = maxSize.width
        var domainSize = self.domainLabel.sizeThatFits(maxSize)
        domainSize.width = min(domainSize.width, descriptionRect.width)
        
        guard self.titleLabel.attributedText != nil else {
            var yPosition = (descriptionRect.height - domainSize.height) / 2
            yPosition += insets.top
            
            self.domainLabel.frame = CGRect(origin: CGPoint(x: xPosition, y: yPosition), size: domainSize)
            return
        }
        
        maxSize.height -= domainSize.height
        maxSize.height -= titleToDomainSpacing
        
        self.titleLabel.preferredMaxLayoutWidth = descriptionRect.width
        var titleSize = self.titleLabel.sizeThatFits(maxSize)
        titleSize.width = min(titleSize.width, descriptionRect.width)
        let combinedHeight = titleSize.height + domainSize.height + titleToDomainSpacing
        var yPosition = (descriptionRect.height - combinedHeight) / 2
        yPosition += insets.top
        
        self.titleLabel.frame = CGRect(origin: CGPoint(x: xPosition, y: yPosition), size: titleSize)
        yPosition += titleSize.height
        yPosition += titleToDomainSpacing
        
        self.domainLabel.frame = CGRect(origin: CGPoint(x: xPosition, y: yPosition), size: domainSize)
        
    }
    
    // MARK: - Size
    
    override var intrinsicContentSize: CGSize {
        guard self.isVideoPreview else {
            return CGSize(width: UIViewNoIntrinsicMetric, height: 78)
        }
        let width = UIScreen.main.bounds.width
        let height = PostLinkPreviewView.height(for: self.link, inWidth: width, isVideoPreview: self.isVideoPreview)
        return CGSize(width: width, height: height)
    }
    
    class func height(for link: URL?, inWidth width: CGFloat, isVideoPreview: Bool) -> CGFloat {
        if isVideoPreview {
            let ratio: CGFloat = 16 / 9
            let insets = UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
            let videoWidth = width - insets.left - insets.right
            let imageHeight = videoWidth / ratio
            let descriptionHeight: CGFloat = 65
            let height: CGFloat = imageHeight + descriptionHeight + insets.bottom + insets.top
            return ceil(height)
        } else {
            return 78
        }
    }

}
