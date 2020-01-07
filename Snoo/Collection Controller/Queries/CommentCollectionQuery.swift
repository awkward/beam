//
//  CommentCollectionQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 26-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class CommentCollectionQuery: ContentCollectionQuery {
    
    public var post: Post?
    public var parentComment: Comment?
    public var depth: Int = 0
    
    public override init() {
        super.init()
        self.sortType = CollectionSortType.best
    }

    override public var apiPath: String {
        let context = post?.managedObjectContext
        
        if let postID = self.post?.objectID,
            let post = context?.object(with: postID) as? Post,
            let postIdentifier = post.identifier,
            let subreddit = post.subreddit {
                let subperma = subreddit.permalink ?? "/r/\(subreddit.displayName ?? "")/"
                return "\(subperma)comments/\(postIdentifier).json"
        }
        if let postPermalink = self.post?.permalink {
            return "\(postPermalink).json"
        }
        
        return "\(self.sortType.rawValue).json"
    }
    
    override var apiQueryItems: [URLQueryItem]? {
        let context = post?.managedObjectContext
        
        var queryItems = [URLQueryItem]()
        
        if self.post?.objectID != nil {
                if let parentCommentID = self.parentComment?.objectID, let parentCommentIdentifier = (context?.object(with: parentCommentID) as! Comment).identifier {
                    queryItems.append(URLQueryItem(name: "comment", value: parentCommentIdentifier))
                }
            
                queryItems.append(URLQueryItem(name: "depth", value: "\(self.depth)"))
                queryItems.append(URLQueryItem(name: "sort", value: self.sortType.rawValue))
        }
        if queryItems.count > 0 {
            return queryItems
        } else {
            return nil
        }
    }
    
    override public func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        return nil
    }
    
    override public func collectionType() -> ObjectCollection.Type {
        return ContentCollection.self
    }
    
    override public var sortType: CollectionSortType {
        didSet {
            if !self.sortType.isSupported(CollectionSortContext.comments) {
                print("The sortType \(self.sortType) might not be supported for comments and lead to unwanted behavior")
            }
        }
    }
    
}
