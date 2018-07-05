//
//  SubredditMetadata.swift
//  CherryKit
//
//  Created by Laurin Brandner on 29/06/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

public struct SubredditMetadata {

    public var ID: String
    
    public var title: String?
    
    public var displayName: String
    
    public var path: String?
    
    public var name: String?
    
    public var imageURL: URL?
    
    public var iconURL: URL?
    
    public var isPrivate = false
    
    public var numberOfSubscribers: Int?
    
    public var recommendedPosts: [String]?
    
    public var related: [String]?
    
    init?(JSON: [String: AnyObject]) {
        if let ID = JSON["id"] as? String,
            let displayName = JSON["display_name"] as? String {
                self.ID = ID
                self.title = JSON["title"] as? String
                self.displayName = displayName
                self.path = JSON["path"] as? String
                self.name = JSON["name"] as? String
                self.numberOfSubscribers = JSON["subscribers"] as? Int
                self.recommendedPosts = []
                self.related = []
                
                if let iconURLString = JSON["icon"] as? String, let iconURL = URL(string: iconURLString) {
                    self.iconURL = iconURL
                }
                
                if let imageURLString = JSON["image"] as? String,
                    let imageURL = URL(string: imageURLString) {
                        self.imageURL = imageURL
                } else if let imageURLString = JSON["image_url"] as? String, let imageURL = URL(string: imageURLString) {
                    self.imageURL = imageURL
                }
                
                if let subredditType = JSON["subreddit_type"] as? String {
                    self.isPrivate = (subredditType == "private")
                }
        } else {
            return nil
        }
    }
    
}

extension SubredditMetadata: Equatable {}

public func == (lhs: SubredditMetadata, rhs: SubredditMetadata) -> Bool {
    return lhs.ID == rhs.ID
}
