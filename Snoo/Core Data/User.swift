//
//  User.swift
//  Snoo
//
//  Created by Robin Speijer on 10-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

@objc(User)
public final class User: SyncObject {

    override open class func entityName() -> String {
        return "User"
    }
    
    override func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        try super.parseObject(json, cache: cache)
     
        self.username = json["name"] as? String ?? self.username
        self.isGold = json["is_gold"] as? NSNumber ?? self.isGold
        self.isOver18 = json["over_18"] as? NSNumber ?? self.isOver18
        self.hasModMail = json["has_mod_mail"] as? NSNumber ?? self.hasModMail
        self.hasMail = json["has_mail"] as? NSNumber ?? self.hasMail
        self.linkKarmaCount = json["link_karma"] as? NSNumber ?? self.linkKarmaCount
        self.commentKarmaCount = json["comment_karma"] as? NSNumber ?? self.commentKarmaCount
        
        if let registrationUtc = json["created_utc"] as? NSNumber, self.registrationDate == nil {
            self.registrationDate = Date(timeIntervalSince1970: registrationUtc.doubleValue)
        }
        
    }
    
    open override func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = super.redditDictionaryRepresentation()
        
        dictionary["name"] = self.username as AnyObject?
        dictionary["is_gold"] = self.isGold
        dictionary["over_18"] = self.isOver18
        dictionary["had_mod_mail"] = self.hasModMail
        dictionary["has_mail"] = self.hasMail
        dictionary["link_karma"] = self.linkKarmaCount
        dictionary["comment_karma"] = self.commentKarmaCount
        dictionary["created_utc"] = self.registrationDate?.timeIntervalSince1970 as AnyObject?
        
        return dictionary
    }

}
