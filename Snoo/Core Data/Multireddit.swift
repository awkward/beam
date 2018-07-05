//
//  Multireddit.swift
//  Snoo
//
//  Created by Robin Speijer on 10-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

@objc(Multireddit)
public final class Multireddit: Subreddit {

    open class override func entityName() -> String {
        return "Multireddit"
    }
    
    override class func insertObject(_ context: NSManagedObjectContext) -> SyncObject {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName(), in: context)!
        return Multireddit(entity: entityDescription, insertInto: context)
    }
    
    override func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        try super.parseObject(json, cache: cache)
        
        self.copiedFrom = json["copied_from"] as? String ?? self.copiedFrom
        self.canEdit = json["can_edit"] as? NSNumber ?? self.canEdit
        self.visibilityString = json["visibility"] as? String ?? self.visibilityString
        self.permalink = json["path"] as? String ?? self.permalink
        self.descriptionText = (json["description_md"] as? String)?.stringByUnescapeHTMLEntities() ?? self.descriptionText
        //Working around a bug in the reddit API. The reddit api has an unused "display_name" field that always contains the first name given to a subreddit. While the "name" field is used everywhere else.
        self.displayName = json["name"] as? String ?? self.displayName
        
        //Only parse subreddits when the are dictionaries containing the data key.
        if let subredditSummaries = json["subreddits"] as? [[String: AnyObject]], subredditSummaries.first?["data"] != nil {
            let subreddits = NSMutableSet(capacity: subredditSummaries.count)
            for subredditSummary in subredditSummaries {
                if let subredditData = subredditSummary["data"] as? [String: AnyObject], let context = self.managedObjectContext {
                    do {
                        let subreddit = try Subreddit.objectWithDictionary(subredditData as NSDictionary, cache: cache, context: context)
                        try subreddit.parseObject(subredditData as NSDictionary, cache: cache)
                        subreddits.add(subreddit)
                    } catch let error as NSError {
                        NSLog("Could not parse subreddit in multireddit: %@", error)
                    } catch {
                        NSLog("Could not parse subreddit in multireddit.")
                    }
                }
            }
            self.subreddits = subreddits
        }
        
    }
    
    func jsonRepresentation() throws -> String? {
        
        var dictionary = [String: Any]()
        dictionary["description_md"] = self.descriptionText as AnyObject?
        dictionary["display_name"] = self.displayName as AnyObject?
        dictionary["icon_name"] = "" as AnyObject?
        dictionary["key_color"] = "#000000" as AnyObject?
        let subredditsDict = self.subreddits?.map({ (subreddit) -> [String: AnyObject] in
            return ["name": (subreddit as? Subreddit)?.displayName as AnyObject? ?? "" as AnyObject]
        })
        dictionary["subreddits"] = subredditsDict ?? []
        dictionary["visibility"] = self.visibilityString as AnyObject?
        dictionary["path"] = self.permalink as AnyObject?
        
        return NSString(data: try JSONSerialization.data(withJSONObject: dictionary, options: []), encoding: String.Encoding.utf8.rawValue) as String?
    }
    
    override open func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = super.redditDictionaryRepresentation()
        
        dictionary["description_md"] = self.descriptionText as AnyObject?
        dictionary["display_name"] = self.displayName as AnyObject?
        let subredditsDict = self.subreddits?.map({ (subreddit) -> [String: AnyObject] in
            return ["name": (subreddit as? Subreddit)?.displayName as AnyObject? ?? "" as AnyObject]
        })
        dictionary["subreddits"] = subredditsDict as AnyObject?? ?? []
        dictionary["visibility"] = self.visibilityString as AnyObject?
        dictionary["path"] = self.permalink as AnyObject?
        
        return dictionary
    }
    
}
