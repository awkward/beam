//
//  Message.swift
//  Snoo
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public enum MessageBox: String {
    case inbox
    case unread
    case sent
}

public final class Message: InteractiveContent {

    override open class func entityName() -> String {
        return "Message"
    }
    
    override func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        try super.parseObject(json, cache: cache)
        
        //Some messages on reddit start with whitespace, however the reddit website doesn't display them, so neither should we.
        if let body = json["body"] as? String {
            self.content = body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).stringByUnescapeHTMLEntities()
        } else {
            self.content = self.content
        }
        self.postTitle = json["link_title"] as? String ?? self.postTitle
        self.subject = json["subject"] as? String ?? self.subject
        self.unread = json["new"] as? NSNumber ?? self.unread
        self.destination = json["dest"] as? String ?? self.destination
        
        if let referenceInfo = json["snoo_reference"] as? [String: AnyObject], let name = referenceInfo["name"] as? String {
            do {
                if let referenceType = try SyncObject.identifierAndTypeWithObjectName(name) {
                    switch referenceType.type {
                    case SyncObjectType.CommentType:
                        self.reference = try Comment.objectWithDictionary(referenceInfo as NSDictionary, cache: nil, context: self.managedObjectContext!) as! Comment
                    case SyncObjectType.LinkType:
                        self.reference = try Post.objectWithDictionary(referenceInfo as NSDictionary, cache: nil, context: self.managedObjectContext!) as! Post
                    default:
                        print("Invalid beam_reference")
                    }
                }
            } catch {
                print("Could not parse refence object for message")
            }
        }
    }
    
    open override func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = super.redditDictionaryRepresentation()
        
        dictionary["body"] = self.content as AnyObject?
        dictionary["link_title"] = self.postTitle as AnyObject?
        dictionary["subject"] = self.subject as AnyObject?
        dictionary["new"] = self.unread
        dictionary["dest"] = self.destination as AnyObject?
        dictionary["snoo_reference"] = self.reference?.redditDictionaryRepresentation() as AnyObject?
        
        return dictionary
    }

}
