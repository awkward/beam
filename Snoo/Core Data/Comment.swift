//
//  Comment.swift
//  Snoo
//
//  Created by Robin Speijer on 10-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

@objc(Comment)
open class Comment: InteractiveContent {

    open class override func entityName() -> String {
        return "Comment"
    }
    
    override class func insertObject(_ context: NSManagedObjectContext) -> SyncObject {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName(), in: context)!
        return Comment(entity: entityDescription, insertInto: context)
    }
    
    override func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        try super.parseObject(json, cache: cache)
        
        guard self.managedObjectContext != nil else {
            let userInfo: [String: String] = [NSLocalizedDescriptionKey: "Tried to parse deleted object"]
            throw NSError(domain: SnooErrorDomain, code: 500, userInfo: userInfo)
        }
        
        func objectWithJSONKey(_ key: String) throws -> SyncObject? {
            if let subredditName: String = json[key] as? String, let subredditObjectType = try SyncObject.identifierAndTypeWithObjectName(subredditName) {
                let itemClass: SyncObject.Type = subredditObjectType.type.itemClass
                return try itemClass.objectWithIdentifier(subredditObjectType.identifier, cache: cache, context: self.managedObjectContext!)
            }
            return nil
        }
        
        self.post = try objectWithJSONKey("link_id") as? Post
        
        if (json["context"] != nil || json["link_id"] != nil) && (self.post?.subreddit == nil || self.post?.permalink == nil) {
            var postID: String?
            var permalink: String?
            if let context: String = json["context"] as? String, var components = URLComponents(string: context) {
                let path = components.path
                let pathComponents: [String] = path.components(separatedBy: "/")
                permalink = path
                if pathComponents.count > 3 {
                    if pathComponents[3] == "comments" || pathComponents[3] == "/" {
                        postID = pathComponents[4]
                    } else {
                        postID = pathComponents[3]
                    }
                    
                }
            }
            
            if let linkID: String = json["link_id"] as? String {
                postID = SyncObject.identifierWithObjectName(linkID)
            }
            
            if let postID: String = postID, let post: Post = try Post.objectWithIdentifier(postID, cache: nil, context: self.managedObjectContext!) as? Post {
                if let postTitle: String = json["link_title"] as? String {
                    post.title = postTitle.stringByUnescapeHTMLEntities()
                }
                if let postAuthor: String = json["link_author"] as? String {
                    post.author = postAuthor
                }
                if let subredditID: String = json["subreddit_id"] as? String, let subreddit: String = json["subreddit"] as? String {
                    let subredditDictionary: [String: String] = ["name": subredditID, "display_name": subreddit]
                    if let subreddit: Subreddit = try Subreddit.objectWithDictionary(subredditDictionary as NSDictionary, cache: nil, context: self.managedObjectContext!) as? Subreddit {
                        try subreddit.parseObject(subredditDictionary as NSDictionary, cache: nil)
                        post.subreddit = subreddit
                    }
                }
                if let permalink: String = permalink?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                    post.permalink = permalink
                }
                if post.hasBeenReported == false {
                    post.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
                }
                
                self.post = post
            }
        }
        
        if let parentID: String = json["parent_id"] as? String, parentID.range(of: "t1_") != nil {
            let parentCommentID: String = parentID.replacingOccurrences(of: "t1_", with: "")
            if let parentComment: Comment = try Comment.objectWithIdentifier(parentCommentID, cache: nil, context: self.managedObjectContext!) as? Comment {
                self.parent = parentComment
            }
        }
        
    }
    
    open override func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = super.redditDictionaryRepresentation()
        
        dictionary["parent_id"] = self.parent?.objectName as AnyObject?
        dictionary["link_title"] = self.post?.title as AnyObject?
        dictionary["link_id"] = self.post?.objectName as AnyObject?
        
        return dictionary
    }
    
}
