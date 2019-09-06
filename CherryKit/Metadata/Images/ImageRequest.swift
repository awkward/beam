//
//  ImageRequest.swift
//  CherryKit
//
//  Created by Robin Speijer on 15-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

/// A request for the metdata of an image
public struct ImageRequest {
    
    /// The reddit post ID
    public var postID: String
    
    /// The URL of the reddit post. For example http://i.imgur.com/spygYxW.jpg
    public var imageURL: String
    
    public init(postID: String, imageURL: String) {
        self.postID = postID
        self.imageURL = imageURL
    }
    
}

extension ImageRequest: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.postID)
        hasher.combine(self.imageURL)
    }
    
}
