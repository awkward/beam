//
//  ImgurAlbumRequest.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

public class ImgurAlbumRequest: ImgurRequest {
    
    var albumTitle: String?
    var albumDescription: String?
    open var imageIdentifiers: [String]?
    open var imageDeleteHashes: [String]?
    
    public init(createRequestWithTitle title: String?, description: String?) {
        super.init()
        self.HTTPMethod = ImgurHTTPMethod.Create
        self.endpoint = "album"
        self.albumTitle = title
        self.albumDescription = description
    }
    
    public init(updateRequestWithIdentifier identifier: String, title: String?, description: String?) {
        super.init()
        self.HTTPMethod = ImgurHTTPMethod.Update
        self.endpoint = "album/\(identifier)"
        self.albumTitle = title
        self.albumDescription = description
    }
    
    public init(deleteRequestWithDeleteHash deleteHash: String) {
        super.init()
        self.HTTPMethod = ImgurHTTPMethod.Delete
        self.deleteHash = deleteHash
        self.endpoint = "album/\(deleteHash)"
    }
    
    public init(identifier: String) {
        super.init()
        self.HTTPMethod = ImgurHTTPMethod.Get
        self.endpoint = "album/\(identifier)"
    }
    
    internal override func addParameters() {
        var parameters = [String: Any]()
        
        if let identifiers = self.imageIdentifiers {
            parameters["ids"] = identifiers
        }
        
        if let hashes = self.imageDeleteHashes {
            parameters["deletehashes"] = hashes
        }
        
        if let title = self.albumTitle {
            parameters["title"] = title
        }
        if let description = albumDescription {
            parameters["description"] = description
        }
        self.parameters = parameters
    }
    
    override func parseResponse(_ json: NSDictionary, response: HTTPURLResponse) throws -> AnyObject {
        if let data = json["data"] as? NSDictionary {
            return ImgurAlbum(dictionary: data)
        } else {
            throw NSError.imgurKitError(500, message: "Invalid response")
        }
    }
    
}
