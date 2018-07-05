//
//  InteractiveContent.swift
//  Snoo
//
//  Created by Robin Speijer on 17-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

open class InteractiveContent: Content {
    
    /// Enumerates all (child)replies en return them all as a Set.
    open var allReplies: [InteractiveContent]? {
        
        if let replies = self.replies?.array as? [InteractiveContent] {
            var allReplies = [InteractiveContent]()
            for reply in replies {
                allReplies.append(reply)
                
                if let childReplies = reply.allReplies {
                    allReplies.append(contentsOf: childReplies)
                }
            }
            return allReplies
        }
        return nil
        
    }
    
    /// The most recent reply
    open var latestReply: InteractiveContent? {
        
        let sortedReplies = allReplies?.sorted(by: { (obj0: InteractiveContent, obj1: InteractiveContent) -> Bool in
            let date0 = obj0.creationDate?.timeIntervalSince1970 ?? 0
            let date1 = obj1.creationDate?.timeIntervalSince1970 ?? 0
            return date0 > date1
        })
        return sortedReplies?.first
        
    }
    
    // MARK: - Parsing
    
    override open class func entityName() -> String {
        return "InteractiveContent"
    }

    override func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        try super.parseObject(json, cache: cache)
        
        if let replyData = (json["replies"] as? [String: AnyObject])?["data"] as? [String: AnyObject], let context = self.managedObjectContext {
            
            let parsingOperation = CollectionParsingOperation(query: CollectionQuery())
            parsingOperation.data = replyData as NSDictionary?
            parsingOperation.objectContext = context
            
            let replies = (try parsingOperation.parseListing(replyData as NSDictionary)).filtered(using: NSPredicate(format: "self isKindOfClass: %@", argumentArray: [InteractiveContent.self]))
            self.replies = replies
        }
    }
    
    open override func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = super.redditDictionaryRepresentation()
        
        dictionary["parent_id"] = self.parent?.objectName as AnyObject?
        
        return dictionary
    }

}
