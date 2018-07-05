//
//  ImgurImageUploadRequest.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Photos

public class ImgurImageUploadRequest: ImgurUploadRequest {
    
    open var imageTitle: String?
    open var imageDescription: String?
    
    public override init(image: UIImage) {
        super.init(image: image)
        self.endpoint = "image"
    }
    
    public override init(asset: PHAsset) {
        super.init(asset: asset)
        self.endpoint = "image"
    }
    
    override func addParameters() {
        var parameters = [String: String]()
        if let title = self.imageTitle {
            parameters["title"] = title
        }
        if let description = self.imageDescription {
            parameters["description"] = description
        }
        self.parameters = parameters as [String: NSObject]?
    }
    
    override func parseResponse(_ json: NSDictionary, response: HTTPURLResponse) throws -> AnyObject {
        if let data = json["data"] as? NSDictionary, data["id"] is String {
            return ImgurImage(dictionary: data)
        } else {
            throw NSError.imgurKitError(500, message: "Invalid response")
        }
    }
    
}
