//
//  BeamImageLoader.swift
//  Beam
//
//  Created by Rens Verhoeven on 10-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import SDWebImage

class BeamImageLoader: NSObject {
    
    func startDownloadingImageWithURL(_ url: URL, downscalingOptions: DownscaledImageOptions? = nil, progressHandler: ((_ totalBytesWritten: Int, _ totalBytesExpectedToWrite: Int) -> Void)? = nil, completionHandler:  ((_ image: UIImage?) -> Void)?) -> SDWebImageOperation? {
        let operation = SDWebImageManager.shared().loadImage(with: url, options: [], progress: { (receivedSize, expectedSize, _) in
            DispatchQueue.main.async { () -> Void in
                progressHandler?(receivedSize, expectedSize)
            }
        }, completed: { (image, _, _, _, _, url) in
            guard let image = image else {
                DispatchQueue.main.async { () -> Void in
                    completionHandler?(nil)
                }
                return
            }
            let options = downscalingOptions ?? DownscaledImageOptions()
            let scaledImage = UIImage.downscaledImageWithImage(image, options: options)
            
            if let cacheKey = url?.absoluteString, downscalingOptions == nil {
                SDImageCache.shared().store(scaledImage, forKey: cacheKey + "_scaled", toDisk: true)
            }
            
            DispatchQueue.main.async { () -> Void in
                completionHandler?(scaledImage)
            }

        })
        return operation
    }

}
