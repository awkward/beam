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
        return try! DataController.shared.performBackgroundTaskAndWait { (context) -> String in
            
            let defaultPath = "\(self.sortType.rawValue).json"
            guard let postID = self.post?.objectID,
                let post = context.object(with: postID) as? Post,
                let postIdentifier = post.identifier else {
                    return defaultPath
            }
            
            if let subreddit = post.subreddit {
                let perma = subreddit.permalink ?? "/r/\(subreddit.displayName ?? "")/"
                return "\(perma)comments/\(postIdentifier).json"
            } else if let postPermalink = post.permalink {
                return "\(postPermalink).json"
            } else {
                return defaultPath
            }
        }
    }
    
    override var apiQueryItems: [URLQueryItem]? {
        return try! DataController.shared.performBackgroundTaskAndWait { (context) -> [URLQueryItem]? in
            var queryItems = [URLQueryItem]()
            
            if let parentCommentObjectID = self.parentComment?.objectID,
                let parentComment = context.object(with: parentCommentObjectID) as? Comment,
                let commentID = parentComment.identifier {
                queryItems.append(URLQueryItem(name: "comment", value: commentID))
            }
        
            queryItems.append(URLQueryItem(name: "depth", value: "\(self.depth)"))
            queryItems.append(URLQueryItem(name: "sort", value: self.sortType.rawValue))

            if queryItems.count > 0 {
                return queryItems
            } else {
                return nil
            }
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
