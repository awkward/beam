//
//  Content.swift
//  Snoo
//
//  Created by Robin Speijer on 16-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public enum VoteStatus: Int {
    case neutral = 0
    case up = 1
    case down = -1
    
    public static func statusFromBool(_ likes: Bool?) -> VoteStatus {
        guard likes != nil else {
            return .neutral
        }
        
        switch likes! {
        case true:
            return .up
        case false:
            return .down
        }
    }
    
    public func description() -> String {
        switch self {
        case .down:
            return "Down"
        case .up:
            return "Up"
        case .neutral:
            return "Neutral"
        }
    }
}

@objc(Content)
open class Content: SyncObject {
    
    override class func cacheIdentifier(_ identifier: String) -> NSString {
        return "\(self.entityName())-\(identifier)" as NSString
    }
    
    override open class func entityName() -> String {
        return "Content"
    }

    override func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        try super.parseObject(json, cache: cache)
        
        self.permalink = (json["permalink"] as? String)?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? self.permalink
        self.content = (json["body"] as? String)?.stringByUnescapeHTMLEntities() ?? self.content
        self.downvoteCount = json["downs"] as? NSNumber ?? self.downvoteCount
        self.upvoteCount = json["ups"] as? NSNumber ?? self.upvoteCount
        self.isSaved = json["saved"] as? NSNumber ?? self.isSaved
        self.gildCount = json["gilded"] as? NSNumber ?? self.gildCount
        self.author = json["author"] as? String ?? self.author
        self.score = json["score"] as? NSNumber ?? self.score
        self.scoreHidden = json["score_hidden"] as? NSNumber ?? self.scoreHidden
        self.stickied = json["stickied"] as? NSNumber ?? self.stickied
        if let archived = json["archived"] as? NSNumber {
            self.archived = archived
        } else {
            self.archived = false
        }
        if let locked = json["locked"] as? NSNumber {
            self.locked = locked
        } else {
            self.locked = false
        }
        self.authorFlairText = json["author_flair_text"] as? String ?? self.authorFlairText
        if let likes = json["likes"] as? NSNumber {
            self.voteStatus = NSNumber(value: VoteStatus.statusFromBool(likes.boolValue).rawValue)
        }
     
        if let creationEpoch = json["created_utc"] as? NSNumber, self.creationDate == nil {
            self.creationDate = Date(timeIntervalSince1970: creationEpoch.doubleValue)
        }
    }
    
    override open func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = super.redditDictionaryRepresentation()
        
        dictionary["permalink"] = self.permalink as AnyObject?
        dictionary["body"] = self.content as AnyObject?
        dictionary["downs"] = self.downvoteCount
        dictionary["ups"] = self.upvoteCount
        dictionary["gilded"] = self.gildCount
        dictionary["score"] = self.score
        dictionary["author"] = self.author as AnyObject?
        dictionary["score_hidden"] = self.scoreHidden
        dictionary["saved"] = self.isSaved
        dictionary["stickied"] = self.stickied
        dictionary["archived"] = self.archived
        dictionary["locked"] = self.locked
        
        dictionary["likes"] = self.voteStatus?.intValue == 0 ? nil: self.voteStatus?.intValue
        
        dictionary["created_utc"] = self.creationDate?.timeIntervalSince1970 as AnyObject?
        
        return dictionary
    }
    
    open func insertNewMediaObject() -> MediaObject {
        var insertedObject: MediaObject?
        self.managedObjectContext?.performAndWait({ () -> Void in
            // Insertion
            if let context = self.managedObjectContext,
                let entity = NSEntityDescription.entity(forEntityName: MediaObject.entityName(), in: context) {
                //swiftlint:disable explicit_init
                insertedObject = MediaObject.init(entity: entity, insertInto: context)
            }
            
            // Assignment
            if let object = insertedObject, (self.mediaObjects == nil || self.mediaObjects?.count == 0) {
                self.mediaObjects = NSOrderedSet(object: object)
            } else if let object = insertedObject {
                let newSet = NSMutableOrderedSet(orderedSet: self.mediaObjects!)
                newSet.add(object)
                self.mediaObjects = newSet
            }
        })
        
        if let insertedObject = insertedObject {
            return insertedObject
        } else {
            fatalError()
        }
    }
    
    open func removeMediaObject(_ object: MediaObject) {
        if let mediaObjects = self.mediaObjects {
            let newSet = NSMutableOrderedSet(orderedSet: mediaObjects)
            newSet.remove(object)
            self.mediaObjects = newSet
        }
    }
    
    /**
     Updates the content's score by adding or substracting based on the old and new vote status.
     
     - parameter newVoteStatus: the new vote status, the one the user selected.
     - parameter oldVoteStatus: the old vote status, before the new vote status was set. If nil the current vote status is used.
     */
    open func updateScore(_ newVoteStatus: VoteStatus, oldVoteStatus: VoteStatus?) {
        var previousVoteStatus: VoteStatus! = oldVoteStatus
        if previousVoteStatus == nil {
            previousVoteStatus = VoteStatus(rawValue: self.voteStatus?.intValue ?? 0)
        }
        var addSubstract: Int = 0
        if newVoteStatus == VoteStatus.up && previousVoteStatus == VoteStatus.down {
            addSubstract = 2
        } else if newVoteStatus == VoteStatus.down && previousVoteStatus == VoteStatus.up {
            addSubstract = -2
        } else if previousVoteStatus == VoteStatus.neutral {
            addSubstract = newVoteStatus.rawValue
        } else if newVoteStatus == VoteStatus.neutral {
            addSubstract = -1 * previousVoteStatus.rawValue
        }
        self.score = NSNumber(value: (self.score?.intValue ?? 0) + addSubstract)
    }
    
    open var hasBeenDeleted: Bool {
        return (self.author == "[deleted]" || self.author == "[removed]") && (self.content == "[deleted]" || self.content == "[removed]")
    }
    
}
