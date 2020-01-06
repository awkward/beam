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
public class Subreddit: SyncObject {

    public class override func entityName() -> String {
        return "Subreddit"
    }
    
    override class func insertObject(_ context: NSManagedObjectContext) -> SyncObject {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName(), in: context)!
        return Subreddit(entity: entityDescription, insertInto: context)
    }
    
    public static var frontpageIdentifier: String {
        return "snoo-frontpage"
    }
    
    public static var allIdentifier: String {
        return "snoo-all"
    }
    
    public var isPrepopulated: Bool {
        if let identifier = self.identifier {
            return [Subreddit.frontpageIdentifier, Subreddit.allIdentifier].contains(identifier)
        }
        return false
    }
    
    public var visibility: SubredditVisibility {
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
    
    public var submissionType: SubredditSubmissionType {
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
            let firstChar = title[..<title.index(title.startIndex, offsetBy: 1)].uppercased()
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
            self.sectionName = title[..<title.index(title.startIndex, offsetBy: 1)].uppercased()
        } else {
            self.sectionName = nil
        }
        NotificationCenter.default.post(name: .SubredditBookmarkDidChange, object: self)
    }
    
    //Returns the frontpage subreddit. If it doesn't already exist in the context it will be created. This method is always done on the DataController's private context!
    public class func frontpageSubreddit() throws -> Subreddit {
        return try prepopulatedSubreddit(identifier: Subreddit.frontpageIdentifier, customization: { subreddit in
            subreddit.permalink = ""
            subreddit.sectionName = ""
            subreddit.order = NSNumber(value: 0)
            subreddit.title = NSLocalizedString("subreddit-frontpage", comment: "The title used for the frontpage secction on reddit. This is a collection of your subbreddits when logged in")
            subreddit.displayName = NSLocalizedString("subreddit-frontpage", comment: "The title used for the frontpage secction on reddit. This is a collection of your subbreddits when logged in")
            subreddit.isBookmarked = NSNumber(value: true)
        })
    }
    
    //Returns the /r/all subreddit. If it doesn't already exist in the context it will be created. This method is always done on the DataController's private context!
    public class func allSubreddit() throws -> Subreddit {
        return try prepopulatedSubreddit(identifier: Subreddit.allIdentifier) { subreddit in
            subreddit.permalink = "/r/all"
            subreddit.sectionName = ""
            subreddit.order = NSNumber(value: 1)
            subreddit.title = NSLocalizedString("subreddit-all", comment: "The title used for the all section on reddit. This is a collection of all subbreddits")
            subreddit.displayName = NSLocalizedString("subreddit-all", comment: "The title used for the all scction on reddit. This is a collection of all subbreddits")
            subreddit.isBookmarked = NSNumber(value: true as Bool)
        }
    }
    
    private class func prepopulatedSubreddit(identifier: String, customization block: (Subreddit) throws -> Void) throws -> Subreddit {
        guard let context: NSManagedObjectContext = DataController.shared.privateContext else {
            throw NSError.snooError(localizedDescription: "Unable to obtain private managed object context")
        }
        var subreddit: Subreddit!
        var thrownError: Error?
        context.performAndWait {
            do {
                subreddit = try prepopulatedSubreddit(in: context, identifier: identifier)
                try block(subreddit)
            } catch {
                thrownError = error
            }
        }
        guard subreddit != nil, thrownError == nil else {
            throw thrownError ?? NSError.snooError(localizedDescription: "")
        }
        
        return subreddit
    }
    
    private class func prepopulatedSubreddit(in context: NSManagedObjectContext, identifier: String) throws -> Subreddit {
        if let existing = try Subreddit.fetchObjectWithIdentifier(identifier, context: context) as? Subreddit {
            return existing
        } else if let created = try Subreddit.objectWithIdentifier(identifier, cache: nil, context: context) as? Subreddit {
            try context.obtainPermanentIDs(for: [created])
            return created
        } else {
            throw NSError.snooError(0, localizedDescription: "Unable to create prepopulated subreddit")
        }
    }

    public var isUserAuthorized: Bool {
        return self.visibility == SubredditVisibility.Public || self.isContributor?.boolValue == true || self.isOwner?.boolValue == true || self.isModerator?.boolValue == true || self.isSubscriber?.boolValue == true
    }
    
}
