//
//  GalleryItem+MediaImage.swift
//  beam
//
//  Created by Robin Speijer on 29-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import Snoo

extension Snoo.MediaObject {
    
    var smallThumbnailURL: URL? {
        let pattern = "^https?://.*imgur.com/"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            if let string = self.contentURLString, let url = NSURL(string: string), regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) != nil {
                
                var pathExtension = url.pathExtension ?? ""
                
                let pathWithoutExtension = pathExtension.count > 0 ? url.path?.replacingOccurrences(of: ".\(pathExtension)", with: "") : url.path
                //Imgur always responds with an image if the extension is .png
                pathExtension = "png"
                
                if let pathWithoutExtension = pathWithoutExtension {
                    let imgurProportion = (key: "m", side: 320)
                    
                    let thumbnailPath = "\(pathWithoutExtension)\(imgurProportion.key).\(pathExtension)"
                    var urlComponents = URLComponents(string: string)
                    urlComponents?.path = thumbnailPath
                    return urlComponents?.url
                }
            }
        } catch {
            AWKDebugLog("Small thumbnail regex failed: \(error)")
        }
        return nil
    }
}
