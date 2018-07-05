//
//  Subreddit+Extras.swift
//  Beam
//
//  Created by Rens Verhoeven on 17-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreSpotlight
import MobileCoreServices

extension Subreddit {
    
    fileprivate func searchIdentifier() -> String? {
        if let identifier = self.identifier {
            return identifier
        }
        return nil
    }
    
    fileprivate func webpageURL() -> URL? {
        let host = "www.reddit.com"
        if self.identifier == Subreddit.frontpageIdentifier {
            return URL(string: "https://\(host)")
        }
        if let permalink = self.permalink {
            return URL(string: "https://\((host as NSString).appendingPathComponent(permalink))")
        }
        return nil
    }
    
    fileprivate func searchKeywords() -> [String]? {
        if let displayName: String = self.displayName {
            
            let baseKeywords: [String] = [displayName, "reddit"]
            var keywords: [String] = baseKeywords
            if self.identifier == Subreddit.frontpageIdentifier {
                let specificKeywords: [String] = ["subreddit", "frontpage", "alien", "blue", "alien blue"]
                keywords.append(contentsOf: specificKeywords)
            } else if self is Multireddit {
                let specificKeywords: [String] = ["/m/\(displayName)", "m/\(displayName)", "multireddit"]
                keywords.append(contentsOf: specificKeywords)
            } else {
                let specificKeywords: [String] = ["/r/\(displayName)", "r/\(displayName)", "subreddit"]
                keywords.append(contentsOf: specificKeywords)
            }
            return keywords
        }
        
        return nil
    }
    
    fileprivate func coreSpotlightAttributeSet() -> CSSearchableItemAttributeSet? {
        var returnAttributeSet: CSSearchableItemAttributeSet?
        self.managedObjectContext?.performAndWait {
            if let displayName = self.displayName, self.webpageURL() != nil {
                let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeData as String)
                // Add metadata that supplies details about the item.
                attributeSet.title = displayName
                attributeSet.contentDescription = (self is Multireddit) ? AWKLocalizedString("multireddit") : AWKLocalizedString("subreddit")
                attributeSet.url = self.webpageURL()
                attributeSet.relatedUniqueIdentifier = self.searchIdentifier()
                attributeSet.keywords = self.searchKeywords()
                attributeSet.identifier = self.identifier
                returnAttributeSet = attributeSet
            }
            
        }
        
        return returnAttributeSet
    }
    
    func createUserActivity() -> NSUserActivity? {
        if let displayName = self.displayName, self.webpageURL() != nil {
            let activity = NSUserActivity(activityType: "com.madeawkward.beam.subreddit")
            let url = self.webpageURL()
            activity.webpageURL = url
            activity.userInfo = self.userInfoForUserActivity()
            activity.title = displayName
            activity.requiredUserInfoKeys = Set(["id", "identifier", "display_name", "permalink", "object_name", "is_multireddit"])
            activity.isEligibleForHandoff = true
            activity.isEligibleForSearch = true
            if let keywords = self.searchKeywords() {
                activity.keywords = Set(keywords)
            }
            activity.contentAttributeSet = self.coreSpotlightAttributeSet()
            return activity
        }
        return nil
    }
    
    func createSearchableItem() -> CSSearchableItem? {
        if let attributeSet = self.coreSpotlightAttributeSet(), let searchIdentifier = self.searchIdentifier() {
            return CSSearchableItem(uniqueIdentifier: searchIdentifier, domainIdentifier: nil, attributeSet: attributeSet)
        }
        return nil
    }
    
    func userInfoForUserActivity() -> [String: NSSecureCoding]? {
        if let permalink = self.permalink, let displayName = self.displayName, let identifier = self.identifier {
            return ["is_multireddit": NSNumber(value: (self is Multireddit)), "permalink": permalink as NSSecureCoding, "display_name": displayName as NSSecureCoding, "id": identifier as NSSecureCoding, "identifier": identifier as NSSecureCoding, "object_name": self.objectName! as NSSecureCoding]
        }
        return nil
    }
    
    func createApplicationShortcutItem() -> UIApplicationShortcutItem? {
        if let displayName = self.displayName {
            let item = UIMutableApplicationShortcutItem(type: "com.madeawkward.beam.shortcut.subreddit", localizedTitle: displayName)
            if self.identifier == Subreddit.frontpageIdentifier {
                if #available(iOS 9.1, *) {
                    item.icon = UIApplicationShortcutIcon(type: .home)
                } else {
                    item.icon = nil
                }
            } else {
                item.localizedSubtitle = AWKLocalizedString("favorite-subreddit")
                if #available(iOS 9.1, *) {
                    item.icon = UIApplicationShortcutIcon(type: .favorite)
                } else {
                    item.icon = nil
                }
            }
            
            item.userInfo = self.userInfoForUserActivity()
            return item
        }
        return nil
    }
}
