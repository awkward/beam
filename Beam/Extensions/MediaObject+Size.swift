//
//  MediaObject+Size.swift
//  Beam
//
//  Created by Rens Verhoeven on 04-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

extension MediaObject {

    func aspectRatioSizeWithMaxWidth(_ maxWidth: CGFloat, maxHeight: CGFloat? = nil) -> CGSize? {
        if let imageHeight = self.height?.floatValue, let imageWidth = self.width?.floatValue, imageHeight > 0 && imageWidth > 0 {
            let aspectRatioImageHeight = CGFloat(imageHeight) * maxWidth / CGFloat(imageWidth)
            var newHeight = aspectRatioImageHeight
            if let maxHeight = maxHeight {
                newHeight = min(aspectRatioImageHeight, maxHeight)
            }
            return CGSize(width: maxWidth, height: newHeight)
        }
        return nil
    }
    
    func viewControllerPreviewingSize() -> CGSize {
        if let mediaSize = self.aspectRatioSizeWithMaxWidth(UIScreen.main.bounds.size.width, maxHeight: UIScreen.main.bounds.size.height) {
            return mediaSize
        }
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
    }
    
}
