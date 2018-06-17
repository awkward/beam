//
//  ImageCollectionViewCell.swift
//  AWKImagePickerControllerExample
//
//  Created by Rens Verhoeven on 30-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView?
    
    var asset: PHAsset? {
        didSet {
            if self.asset != oldValue {
                self.imageView?.image = nil
                if let currentRequest = self.currentRequest {
                    PHImageManager.defaultManager().cancelImageRequest(currentRequest)
                }
                if let asset = self.asset {
                    self.currentRequest = PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSize(width: 140, height: 140), contentMode: PHImageContentMode.AspectFill, options: nil) { (image, _) in
                        self.imageView?.image = image
                    }
                }
            }
        }
    }
    
    var currentRequest: PHImageRequestID?
    
}
