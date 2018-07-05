//
//  AssetCollectionViewCell.swift
//  AWKImagePickerController
//
//  Created by Rens Verhoeven on 29-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

class AssetCollectionViewCell: UICollectionViewCell, ColorPaletteSupport {
    
    weak var assetsPickerController: AssetsPickerController? {
        didSet {
            self.startColorPaletteSupport()
        }
    }
    
    class var reuseIdentifier: String {
        return "asset-cell"
    }
    
    internal var imageSize: CGSize = CGSize(width: 100, height: 100) {
        didSet {
            if self.imageSize != oldValue {
                self.shouldUpdateImage = true
            }
        }
    }
    
    internal var imageManager: PHImageManager?
    
    internal var asset: PHAsset? {
        didSet {
            if self.asset != oldValue {
                self.shouldUpdateImage = true
            }
        }
    }
    
    var currentRequest: PHImageRequestID?
    
    fileprivate var shouldUpdateImage = false
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectedOverlay: UIView!
    
    deinit {
        self.stopColorPaletteSupport()
    }
    
    internal func reloadContents() {
        if self.shouldUpdateImage {
            self.shouldUpdateImage = false
            if let currentRequest = self.currentRequest {
                var imageManager = PHImageManager.default()
                if let customImageManager = self.imageManager {
                    imageManager = customImageManager
                }
                NSLog("Canceling request")
                imageManager.cancelImageRequest(currentRequest)
            }
            self.startLoadingImage()
        }
    }
    
    fileprivate func startLoadingImage() {
        self.imageView.image = nil
        if let asset = self.asset {
            var imageManager = PHImageManager.default()
            if let customImageManager = self.imageManager {
                imageManager = customImageManager
            }
            let requestOptions = PHImageRequestOptions()
            requestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
            
            self.imageView.contentMode = UIViewContentMode.center
            self.imageView.image = AssetsPickerControllerStyleKit.imageOfAssetThumbnailPlaceholder
            self.currentRequest = imageManager.requestImage(for: asset, targetSize: self.imageSize.sizeWithScale(UIScreen.main.scale), contentMode: PHImageContentMode.aspectFill, options: requestOptions) { (image, _) in
                if let image = image {
                    self.imageView.contentMode = UIViewContentMode.scaleAspectFill
                    self.imageView.image = image
                }
                
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !self.isSelected
        }
    }
    
    func colorPaletteDidChange() {
        self.imageView.tintColor = self.colorPalette.titleColor.withAlphaComponent(0.3)
        self.contentView.backgroundColor = self.colorPalette.assetCellBackgroundColor
    }
    
}
