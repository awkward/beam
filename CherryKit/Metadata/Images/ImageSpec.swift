//
//  ImageSpec.swift
//  CherryKit
//
//  Created by Robin Speijer on 15-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

/// The specs of one single image
public struct ImageSpec {
    
    /// The direct URL to the image
    public var URL: Foundation.URL
    public var originalURL: Foundation.URL
    public var MP4URL: Foundation.URL?
    
    /// The size of the image
    public var size: CGSize
    
    /// The identifier of the image at the image service
    public var identifier: String?
    
    public var animated: Bool?
    public var mimeType: String?
    public var nsfw: Bool?
    public var filesize: Int?
    public var title: String?
    public var imageDescription: String?
    
    init(JSON: NSDictionary) throws {
        
        if let urlString = JSON["original"] as? NSString, let url = Foundation.URL(string: urlString as String) {
            self.originalURL = url
            if let imageURLString = JSON["image"] as? String, let imageURL = Foundation.URL(string: imageURLString) {
                self.URL = imageURL
            } else {
                self.URL = self.originalURL
            }
        } else if let urlString = JSON["link"] as? NSString, let url = Foundation.URL(string: urlString as String) {
            self.originalURL = url
            self.URL = url
        } else {
            throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Missing original image URL in Cherry response"])
        }
        
        if let urlString = JSON["image"] as? NSString, let url = Foundation.URL(string: urlString as String) {
            self.URL = url
        } else if let urlString = JSON["link"] as? String, let url = Foundation.URL(string: urlString) {
            self.URL = url
        } else {
            self.URL = self.originalURL
        }
        
        if let urlString = JSON["mp4"] as? String, let url = Foundation.URL(string: urlString) {
            self.MP4URL = url
        }
        
        if let width = JSON["width"] as? NSNumber, let height = JSON["height"] as? NSNumber {
            self.size = CGSize(width: width.doubleValue, height: height.doubleValue)
        } else if let width = JSON["width"] as? String, let height = JSON["height"] as? String {
            self.size = CGSize(width: CGFloat((width as NSString).floatValue), height: CGFloat((height as NSString).floatValue))
        } else {
            let message = JSON["message"] as? String
            throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: message ?? "Missing image size info in Cherry response"])
        }
        
        // Optional metadata, if available
        self.animated = (JSON["animated"] as? NSNumber)?.boolValue
        self.mimeType = JSON["type"] as? String
        self.nsfw = (JSON["nsfw"] as? NSNumber)?.boolValue
        self.filesize = (JSON["size"] as? NSNumber)?.intValue
        self.title = JSON["title"] as? String
        self.imageDescription = JSON["description"] as? String
        self.identifier = JSON["id"] as? String
        
    }
    
}

extension ImageSpec: Hashable {
    
    public var hashValue: Int {
        return URL.hashValue ^ size.width.hashValue ^ size.height.hashValue
    }
    
}

public func == (lhs: ImageSpec, rhs: ImageSpec) -> Bool {
    return lhs.URL == rhs.URL && lhs.size == rhs.size
}
