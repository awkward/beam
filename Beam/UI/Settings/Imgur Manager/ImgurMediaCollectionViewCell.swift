//
//  ImgurMediaCollectionViewCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 28-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import ImgurKit
import SDWebImage

class ImgurMediaCollectionViewCell: BeamCollectionViewCell {
    
    var imgurObject: ImgurObject? {
        didSet {
            self.imageTask?.cancel()
            self.mediaImageView.image = nil
            self.fetchImage()
            self.setNeedsUpdateConstraints()
            self.displayModeDidChange()
            self.reloadAlbumIdicators()
        }
    }
    
    var imageTask: URLSessionTask?
    
    // MARK: - Properties
    @IBOutlet var mediaImageView: UIImageView!
    
    @IBOutlet var albumStackUpperView: UIView?
    @IBOutlet var albumStackBottomView: UIView?
    
    @IBOutlet var imageTopConstraint: NSLayoutConstraint?
    @IBOutlet var imageAlbumTopConstraint: NSLayoutConstraint?
    
    @IBOutlet var imageViewOverlay: UIView?
    
    override var isOpaque: Bool {
        didSet {
            if self.mediaImageView != nil {
                self.displayModeDidChange()
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.imageViewOverlay?.isHidden = !self.isHighlighted
        }
    }
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.contentView.isHidden = false
        self.mediaImageView.isHidden = false
        
        UIApplication.stopNetworkActivityIndicator(for: self)
        if self.imgurObject != nil {
            self.imgurObject = nil
        }
        self.imageTask?.cancel()
    }
    
    deinit {
        UIApplication.stopNetworkActivityIndicator(for: self)
        self.imageTask?.cancel()
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
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        if self.albumStackBottomView != nil {
            switch self.displayMode {
            case .dark:
                self.albumStackUpperView?.backgroundColor = UIColor.white
                self.albumStackBottomView?.backgroundColor = UIColor.white
            case .default:
                self.albumStackUpperView?.backgroundColor = UIColor.black
                self.albumStackUpperView?.backgroundColor = UIColor.black
            }
        }
        
        if !self.isOpaque {
            self.contentView.backgroundColor = UIColor.clear
            self.backgroundColor = UIColor.clear
        } else {
            self.contentView.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
            self.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        }
        
        self.mediaImageView.isOpaque = self.isOpaque
        self.mediaImageView.backgroundColor = self.backgroundColor
    
    }
    
    // MARK: - Content
    
    fileprivate var representsAlbum: Bool {
        return self.imgurObject is ImgurAlbum
    }
    
    func reloadAlbumIdicators() {
        var showLines = self.representsAlbum
        if self.mediaImageView.image == nil {
            showLines = false
        }
        self.albumStackBottomView?.isHidden = !showLines
        self.albumStackUpperView?.isHidden = !showLines
    }
    
    fileprivate func fetchImage() {
        var thumbnailURLString: String?
        if let album: ImgurAlbum = self.imgurObject as? ImgurAlbum, let image: ImgurImage = album.images?.first {
            thumbnailURLString = "https://i.imgur.com/\(image.identifier)m.jpg"
        } else if let image: ImgurImage = self.imgurObject as? ImgurImage {
            thumbnailURLString = "https://i.imgur.com/\(image.identifier)m.jpg"
        }
        
        if let thumbnailURLString: String = thumbnailURLString, let URL: URL = URL(string: thumbnailURLString) {
            if let cachedImage: UIImage = SDImageCache.shared().imageFromDiskCache(forKey: thumbnailURLString) {
                self.mediaImageView.image = cachedImage
                self.reloadAlbumIdicators()
            } else {
                let request: URLRequest = URLRequest(url: URL, cachePolicy: NSURLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 60)
                UIApplication.startNetworkActivityIndicator(for: self)
                self.imageTask = URLSession.shared.downloadTask(with: request, completionHandler: { (location, _, _) in
                    if let location: URL = location {
                        var options: DownscaledImageOptions = DownscaledImageOptions()
                        options.constrainingSize = self.mediaImageView.bounds.size
                        options.contentMode = UIViewContentMode.scaleAspectFill
                        let image: UIImage? = UIImage.downscaledImageWithFileURL(location, options: options)
                        if image != nil {
                            SDImageCache.shared().store(image, forKey: thumbnailURLString, toDisk: true)
                        }
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.mediaImageView.image = image
                            self.imageTask = nil
                            self.reloadAlbumIdicators()
                        })
                    }
                    UIApplication.stopNetworkActivityIndicator(for: self)
                })
                self.imageTask?.resume()
            }
        }
    }
}
