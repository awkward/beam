//
//  StreamAlbumItemView.swift
//  Beam
//
//  Created by Rens Verhoeven on 09-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import SDWebImage

final class StreamAlbumItemView: BeamView, MediaImageLoader, MediaCellMediaLabels {
    
    // MARK: - Image Loading
    
    internal var imageOperation: SDWebImageOperation?
    
    // MARK: - External Properties
    
    var shouldShowNSFWOverlay: Bool = true {
        didSet {
            if self.preparedForShow && self.shouldShowNSFWOverlay != oldValue {
                self.reloadOverlayAndMoreCount()
            }
        }
    }
    var shouldShowSpoilerOverlay: Bool = true {
        didSet {
            if self.preparedForShow && self.shouldShowSpoilerOverlay != oldValue {
                self.reloadOverlayAndMoreCount()
            }
        }
    }
    
    var mediaObject: MediaObject? {
        didSet {
            if self.mediaObject != oldValue {
                self.stopImageLoading()
            }
        }
    }
    
    var moreCount = 0 {
        didSet {
            if self.preparedForShow && self.moreCount != oldValue {
                self.reloadOverlayAndMoreCount()
            }
        }
    }
    
    internal var preferredThumbnailSize: CGSize {
        if self.mediaImageView.bounds.size.width <= 0 {
            //If no size is available, use half of the screensize for the preffered thumbnail size
            return CGSize(width: UIScreen.main.bounds.size.width / 2, height: UIScreen.main.bounds.size.width / 2)
        }
        return self.mediaImageView.bounds.size
    }
    
    fileprivate var preparedForShow = false
    
    // MARK: - View properties
    
    var mediaImageView: UIImageView! = UIImageView()
    internal let progressView = CircularProgressView()
    internal var mediaLabelImageViews: [UIImageView]? = [UIImageView(), UIImageView(), UIImageView()]
    
    //We are only going to make these is we need them
    fileprivate var blurEffectView: UIVisualEffectView?
    fileprivate var vibrancyEffectView: UIVisualEffectView?
    fileprivate var moreLabel: UILabel?
    
    init() {
        super.init(frame: CGRect())
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    fileprivate func setupView() {
        self.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        self.mediaImageView.clipsToBounds = true
        self.mediaImageView.isOpaque = true
        self.mediaImageView.backgroundColor = UIColor.white
        self.mediaImageView.contentMode = UIViewContentMode.scaleAspectFill
        self.addSubview(self.mediaImageView)
        self.addSubview(self.progressView)
    }
    
    func prepareForReuse() {
        self.stopImageLoading()
        self.mediaImageView.image = nil
        self.preparedForShow = false
        self.mediaObject = nil
        self.shouldShowNSFWOverlay = true
        self.shouldShowSpoilerOverlay = true
        self.moreCount = 0
        self.reloadOverlayAndMoreCount()
        
    }
    
    func prepareForShow() {
        if self.mediaObject != nil {
            self.progressView.isHidden = false
            UIApplication.startNetworkActivityIndicator(for: self)
                self.startImageLoading()
        
            self.reloadOverlayAndMoreCount()
            
            self.reloadMediaLabels()
            self.setNeedsLayout()
        } else {
            self.mediaImageView.image = nil
        }
        self.preparedForShow = true
    }
    
    fileprivate func reloadOverlayAndMoreCount() {
        if (self.contentIsNSFW && self.shouldShowNSFWOverlay) || (self.contentIsSpoiler && self.shouldShowSpoilerOverlay) || self.moreCount > 0 {
            self.createEffectView()
            self.blurEffectView!.isHidden = false
            if self.moreCount > 0 {
                self.createMorelabel()
                self.moreLabel?.text = "+ \(self.moreCount)"
                self.vibrancyEffectView!.isHidden = false
                self.moreLabel!.isHidden = false
            } else {
                self.vibrancyEffectView?.isHidden = true
                self.moreLabel?.isHidden = true
            }
        } else {
            self.blurEffectView?.isHidden = true
            self.vibrancyEffectView?.isHidden = true
            self.moreLabel?.isHidden = true
            
        }
    }
    
    fileprivate func createEffectView() {
        if self.blurEffectView == nil {
            let effect = UIBlurEffect(style: UIBlurEffectStyle.dark)
            let effectView = UIVisualEffectView(effect: effect)
            self.addSubview(effectView)
            self.blurEffectView = effectView
        }
    }
    
    fileprivate func createMorelabel() {
        assert(self.blurEffectView != nil, "Warning: effect view is missing when more label is created, more label will not be shown")
        if self.vibrancyEffectView == nil {
            let effect = UIVibrancyEffect(blurEffect: self.blurEffectView!.effect as! UIBlurEffect)
            let effectView = UIVisualEffectView(effect: effect)
            self.blurEffectView?.contentView.addSubview(effectView)
            self.vibrancyEffectView = effectView
        }
        if self.moreLabel == nil {
            let moreLabel = UILabel()
            moreLabel.textAlignment = NSTextAlignment.center
            moreLabel.font = UIFont.systemFont(ofSize: 32, weight: UIFont.Weight.thin)
            moreLabel.textColor = UIColor.black
            self.vibrancyEffectView!.contentView.addSubview(moreLabel)
            self.moreLabel = moreLabel
        }
    }
    
    internal func imageLoadingCompleted() {
        self.progressView.isHidden = true
        UIApplication.stopNetworkActivityIndicator(for: self)
    }
    
    internal func progressDidChange(_ progress: CGFloat) {
        self.progressView.progress = progress
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.progressView.color = DisplayModeValue(UIColor.beamGreyExtraLight(), darkValue: UIColor.white)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.mediaImageView.frame = self.bounds
        
        //Progress view
        let progressViewSize = self.progressView.intrinsicContentSize
        self.progressView.frame = CGRect(origin: CGPoint(x: self.bounds.midX - (progressViewSize.width / 2), y: self.bounds.midY - (progressViewSize.height / 2)), size: progressViewSize)
        
        //Effect view
        self.blurEffectView?.frame = self.bounds
        self.vibrancyEffectView?.frame = self.blurEffectView?.bounds ?? CGRect()
        self.moreLabel?.frame = self.vibrancyEffectView?.bounds ?? CGRect()

        self.layoutMediaLabels(self)
    }

}
