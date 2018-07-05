//
//  ImageAssetCollectionViewCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Photos

protocol ImageAssetCollectionViewCellDelegate: class {
    
    func imageAssetCell(didTapRemoveOnCell cell: ImageAssetCollectionViewCell, image: ImageAsset)
}

class ImageAssetCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: ImageAssetCollectionViewCellDelegate?
    
    @IBOutlet var removeButton: UIButton?
    @IBOutlet var imageView: UIImageView!
    
    var imageAsset: ImageAsset? {
        didSet {
            self.imageAssetDidChange = self.imageAsset != oldValue
        }
    }
    
    var moving = false {
        didSet {
            if self.moving {
                self.alpha = 0.6
                self.transform = CGAffineTransform(scaleX: 1.10, y: 1.10)
            } else {
                self.alpha = 1.0
                self.transform = CGAffineTransform.identity
            }
        }
    }
    
    fileprivate var imageAssetDidChange = false
    
    fileprivate var currentRequest: PHImageRequestID?
    
    func reloadContents(_ imageSize: CGSize, contentMode: PHImageContentMode, imageManager: PHImageManager) {
        if self.imageAssetDidChange {
            if let currentRequest = self.currentRequest {
                imageManager.cancelImageRequest(currentRequest)
            }
            self.imageView.image = nil
            if let imageAsset = self.imageAsset {
                let requestOptions = PHImageRequestOptions()
                requestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
                let retinaImageSize = CGSize(width: imageSize.width * UIScreen.main.scale, height: imageSize.height * UIScreen.main.scale)
                self.currentRequest = imageManager.requestImage(for: imageAsset.asset, targetSize: retinaImageSize, contentMode: contentMode, options: requestOptions, resultHandler: { (image, _) in
                    NSLog("Image Size \(image!.size)")
                    self.imageView.image = image
                })
            }
            
        }
    }
    
    @IBAction fileprivate func removeTapped(_ sender: UIButton) {
        if let image = self.imageAsset {
           self.delegate?.imageAssetCell(didTapRemoveOnCell: self, image: image)
        }
    }
    
}
