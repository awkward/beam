//
//  ImageMetadata.swift
//  CherryKit
//
//  Created by Laurin Brandner on 25/06/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

public func == (lhs: ImageRequest, rhs: ImageRequest) -> Bool {
    return lhs.postID == rhs.postID && lhs.imageURL == rhs.imageURL
}

/// A response holding the metadata of an image
public struct ImageResponse {
    
    /// The original request
    public var request: ImageRequest
    
    /// The specs of the images found at the URL of the request
    public var imageSpecs: [ImageSpec]
    
    init(request: ImageRequest, JSON: NSDictionary) {
        self.request = request
        self.imageSpecs = [ImageSpec]()
        
        let imageDicts = JSON["images"] as? NSArray ?? ((JSON["album"] as? NSDictionary)?["data"] as? NSArray)
        if let imageDicts = imageDicts {
            for imageDict in imageDicts {
                if let imageDict = imageDict as? NSDictionary {
                    do {
                        
                        var spec = try ImageSpec(JSON: imageDict)
                        if let url = URL(string: request.imageURL), (request.imageURL as NSString).pathExtension == "gifv" || (request.imageURL as NSString).pathExtension == "mp4" {
                            spec.URL = url
                            spec.animated = true
                        }
                        self.imageSpecs.append(spec)
                    } catch {
                        //Catch a bug in swift, error is sometimes nil when thrown from an init method
                        NSLog("Could not parse cherry image metadata")
                    }
                }
            }
        }
    }
    
}

extension ImageResponse: Equatable {}

public func == (lhs: ImageResponse, rhs: ImageResponse) -> Bool {
    return lhs.request == rhs.request && lhs.imageSpecs == rhs.imageSpecs
}
