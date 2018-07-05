//
//  Subreddit.swift
//  Snoo
//
//  Created by Robin Speijer on 24-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public enum SubredditVisibility: String {
    case Public = "public"
    case Restricted = "restricted"
    case Private = "private"
    case GoldOnly = "gold_only"
    
    public var publiclyVisible: Bool {
        switch self {
        case .Public, .Restricted:
            return true
        default:
            return false
        }
    }
}

public enum SubredditSubmissionType: String {
    case selfText = "text"
    case link = "link"
    case all = "any"
    case none = "none"
    
    public var canPostLink: Bool {
        switch self {
        case .all, .link:
            return true
        default:
            return false
        }
    }
    
    public var canPostSelfText: Bool {
        switch self {
        case .all, .selfText:
            return true
        default:
            return false
        }
    }
}

@objc(Subreddit)
open class Subreddit: SyncObject {

    open class override func entityName() -> String {
        return "Subreddit"
    }
    
    override class func insertObject(_ context: NSManagedObjectContext) -> SyncObject {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName(), in: context)!
        return Subreddit(entity: entityDescription, insertInto: context)
    }
    
    open static var frontpageIdentifier: String {
        return "snoo-frontpage"
    }
    
    open static var allIdentifier: String {
        return "snoo-all"
    }
    
    open var isPrepopulated: Bool {
        if let identifier = self.identifier {
            return [Subreddit.frontpageIdentifier, Subreddit.allIdentifier].contains(identifier)
        }
        return false
    }
    
    open var visibility: SubredditVisibility {
        get {
            if let visibilityString = self.visibilityString, let visibility = SubredditVisibility(rawValue: visibilityString) {
                return visibility
            }
            //In general subreddits and multireddits you visit in the app are public if they are private you are often subscribed to them
            return SubredditVisibility.Public
        }
        set {
            self.visibilityString = newValue.rawValue
        }
    }
    
    open var submissionType: SubredditSubmissionType {
        get {
            if let submissionTypeString = self.submissionTypeString, let submissionType = SubredditSubmissionType(rawValue: submissionTypeString) {
                return submissionType
            }
            if self.identifier == Subreddit.frontpageIdentifier || self.identifier == Subreddit.allIdentifier || self is Multireddit {
                return SubredditSubmissionType.none
            }
            //In general subreddits you visit will allow both
            return .all
        }
        set {
            self.submissionTypeString = newValue.rawValue
        }
        
    }
    
    override func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        try super.parseObject(json, cache: cache)
        
        self.descriptionText = (json["description"] as? String)?.stringByUnescapeHTMLEntities() ?? self.descriptionText
        self.publicDescription = (json["public_description"] as? String)?.stringByUnescapeHTMLEntities() ?? self.publicDescription
        self.title = (json["title"] as? String)?.stringByUnescapeHTMLEntities() ?? self.title
        self.displayName = json["display_name"] as? String ?? self.displayName
        self.subscribers = json["subscribers"] as? NSNumber ?? self.subscribers
        self.visibilityString = json["subreddit_type"] as? String ?? self.visibilityString
        self.permalink = json["url"] as? String ?? self.permalink
        self.isOwner = json["user_is_owner"] as? NSNumber ?? self.isOwner
        self.isModerator = json["user_is_moderator"] as? NSNumber ?? self.isModerator
        self.isContributor = json["user_is_contributor"] as? NSNumber ?? self.isContributor
        self.isSubscriber = json["user_is_subscriber"] as? NSNumber ?? self.isSubscriber
        self.isNSFW = json["over18"] as? NSNumber ?? self.isNSFW
        self.submissionTypeString = json["submission_type"] as? String ?? self.submissionTypeString
    
        //Create a sectionName for the subreddit if it has not been bookmarked
        if self.isBookmarked.boolValue {
            self.sectionName = ""
        } else if let title = self.displayName {
            let firstChar = title.substring(to: title.index(title.startIndex, offsetBy: 1)).uppercased()
            if Int(firstChar) != nil {
                self.sectionName = "#"
            } else {
                self.sectionName = firstChar
            }
        } else {
            self.sectionName = nil
        }
        
        //If no permalink is set, create one from the displayName
        if let displayName = self.displayName, self.permalink == nil {
            self.permalink = "/r/\(displayName)/"
        }
        
        //Update the expiration date of the subreddit
        if self.hasBeenReported == false {
            self.expirationDate = Date(timeIntervalSinceNow: DataController.SubredditTimeOut)
        }
        
    }
    
    open override func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = super.redditDictionaryRepresentation()
        
        dictionary["description"] = self.descriptionText as AnyObject?
        dictionary["public_description"] = self.publicDescription as AnyObject?
        dictionary["title"] = self.title as AnyObject?
        dictionary["display_name"] = self.displayName as AnyObject?
        dictionary["subscribers"] = self.subscribers
        dictionary["url"] = self.permalink as AnyObject?
        dictionary["over18"] = self.isNSFW
        
        return dictionary
    }
    
    open func changeBookmark(_ isBookmark: Bool) {
        self.isBookmarked = NSNumber(value: isBookmark as Bool)
        if isBookmark {
            self.sectionName = ""
        } else if let title = self.displayName {
            self.sectionName = title.substring(to: title.index(title.startIndex, offsetBy: 1)).uppercased()
        } else {
            self.sectionName = nil
        }
        NotificationCenter.default.post(name: .SubredditBookmarkDidChange, object: self)
    }
    
    //Returns the frontpage subreddit. If it doesn't already exist in the context it will be created. This method is always done on the DataController's private context!
    open class func frontpageSubreddit() throws -> Subreddit {
        let context: NSManagedObjectContext! = DataController.shared.privateContext
        var subreddit: Subreddit!
        var thrownError: Error?
        context.performAndWait {
            do {
                if let existingSubreddit = try Subreddit.fetchObjectWithIdentifier(Subreddit.frontpageIdentifier, context: context) as? Subreddit {
                    //We already have a frontpage subreddit, update it below
                    subreddit = existingSubreddit
                } else {
                    //We don't already have a frontpage subreddit, create it and update it below
                    subreddit = try Subreddit.objectWithIdentifier(Subreddit.frontpageIdentifier, cache: nil, context: context) as! Subreddit
                    subreddit.permalink = ""
                    subreddit.sectionName = ""
                    if subreddit.objectID.isTemporaryID {
                        subreddit.order = NSNumber(value: 0 as Int)
                    }
                    
                    try context?.obtainPermanentIDs(for: [subreddit])
                    try context?.save()
                }
            } catch {
                thrownError = error
            }

        }
        if let thrownError = thrownError {
            throw thrownError
        }
        subreddit.title = NSLocalizedString("subreddit-frontpage", comment: "The title used for the frontpage secction on reddit. This is a collection of your subbreddits when logged in")
        subreddit.displayName = NSLocalizedString("subreddit-frontpage", comment: "The title used for the frontpage secction on reddit. This is a collection of your subbreddits when logged in")
        subreddit.isBookmarked = NSNumber(value: true as Bool)
        
        return subreddit
    }
    
    //Returns the /r/all subreddit. If it doesn't already exist in the context it will be created. This method is always done on the DataController's private context!
    open class func allSubreddit() throws -> Subreddit {
        let context: NSManagedObjectContext! = DataController.shared.privateContext
        var subreddit: Subreddit!
        var thrownError: Error?
        context.performAndWait {
            do {
                if let existingSubreddit = try Subreddit.fetchObjectWithIdentifier(Subreddit.allIdentifier, context: context) as? Subreddit {
                    //We already have a all subreddit, update it below
                    subreddit = existingSubreddit
                } else {
                    //We don't already have a all subreddit, create it and update it below
                    subreddit = try Subreddit.objectWithIdentifier(Subreddit.allIdentifier, cache: nil, context: context) as! Subreddit
                    subreddit.permalink = "/r/all"
                    subreddit.sectionName = ""
                    if subreddit.objectID.isTemporaryID {
                        subreddit.order = NSNumber(value: 1 as Int)
                    }
                    
                    try context?.obtainPermanentIDs(for: [subreddit])
                }
            } catch {
                thrownError = error
            }
            
        }
        if let thrownError = thrownError {
            throw thrownError
        }
        subreddit.title = NSLocalizedString("subreddit-all", comment: "The title used for the all section on reddit. This is a collection of all subbreddits")
        subreddit.displayName = NSLocalizedString("subreddit-all", comment: "The title used for the all scction on reddit. This is a collection of all subbreddits")
        subreddit.isBookmarked = NSNumber(value: true as Bool)
        
        return subreddit
    }

    open var isUserAuthorized: Bool {
        return self.visibility == SubredditVisibility.Public || self.isContributor?.boolValue == true || self.isOwner?.boolValue == true || self.isModerator?.boolValue == true || self.isSubscriber?.boolValue == true
    }
    
}
