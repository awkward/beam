//
//  ImageMetadataRequest.swift
//  CherryKit
//
//  Created by Robin Speijer on 16-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

open class ImageMetadataTaskResult: TaskResult {
    open let metadata: [ImageResponse]
    
    init(metadata: [ImageResponse]) {
        self.metadata = metadata
        super.init(error: nil)
    }
}

open class ImageMetadataTask: Task {
    
    open let imageRequests: [ImageRequest]
    
    override var request: URLRequest {
        var request = cherryRequest("metadata/images", method: RequestMethod.Post)
        
        let imageDicts = self.imageRequests.map { (request: ImageRequest) -> NSDictionary in
            ["post_id": request.postID, "image_url": request.imageURL]
        }
        let bodyDict = ["images": imageDicts]
        let requestBody = try! JSONSerialization.data(withJSONObject: bodyDict, options: [])
        request.httpBody = requestBody
        return request
    }
    
    public init(token: String, imageRequests: [ImageRequest]) {
        self.imageRequests = imageRequests
        super.init(token: token)
    }
    
    override func parseJSONData(_ data: Data) -> TaskResult {
        do {
            let JSON = try JSONSerialization.jsonObject(with: data, options: [])
            if let JSON = JSON as? NSDictionary {
                let metadatas = JSON.map({ (postID, payload) -> ImageResponse? in
                    let imageRequest = self.imageRequests.first(where: { (imageRequest) -> Bool in
                        return imageRequest.postID == postID as! String
                    })
                    if let imageRequest = imageRequest, let payload = payload as? NSDictionary {
                        return ImageResponse(request: imageRequest, JSON: payload)
                    } else {
                        return nil
                    }
                })

                let validMetadatas = metadatas.filter({ (element: ImageResponse?) -> Bool in
                    return element != nil
                }).map({ (element: ImageResponse?) -> ImageResponse in
                    return element!
                })
                
                return ImageMetadataTaskResult(metadata: validMetadatas)
                
            } else {
                throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Could not parse image metadata JSON format"])
            }
        } catch {
            return TaskResult(error: error)
        }
    }
    
}
