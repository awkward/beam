//
//  UserActivityController.swift
//  beam
//
//  Created by Robin Speijer on 14-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

private let RecentlyVisitedSubredditsKey = "recently-visited-subreddits"
private let RecentlySearchedSubredditKeywordsKey = "recently-searched-subreddits"
private let RecentlySearchedPostKeywordsKey = "recently-searched-posts"

class RedditActivityController: NSObject {
    
    static var recentlySearchedSubredditKeywords: [String] {
        guard !UserSettings[.privacyModeEnabled] else {
            return [String]()
        }
        return UserDefaults.standard.object(forKey: RecentlySearchedSubredditKeywordsKey) as? [String] ?? [String]()
    }
    
    static var recentlySearchedPostKeywords: [String] {
        guard !UserSettings[.privacyModeEnabled] else {
            return [String]()
        }
        return UserDefaults.standard.object(forKey: RecentlySearchedPostKeywordsKey) as? [String] ?? [String]()
    }
    
    class var recentlyVisitedSubreddits: [Subreddit] {
        guard !UserSettings[.privacyModeEnabled] else {
            return [Subreddit]()
        }
        let fetchRequest = NSFetchRequest<Subreddit>(entityName: Subreddit.entityName())
        fetchRequest.predicate = NSPredicate(format: "lastVisitDate != nil && NOT(identifier IN %@)", [Subreddit.allIdentifier, Subreddit.frontpageIdentifier])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastVisitDate", ascending: false), NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
        fetchRequest.fetchLimit = 5
        
        do {
            return try AppDelegate.shared.managedObjectContext.fetch(fetchRequest)
        } catch {
            NSLog("Could not fetch recently visited Subreddits: \(error)")
        }
        
        return [Subreddit]()
    }
    
    // MARK: - Adding records
    
    static func addSubredditSearchKeywords(_ keyword: String) {
        guard !UserSettings[.privacyModeEnabled] else {
            return
        }
        self.addValue(keyword, toStringArray: RecentlySearchedSubredditKeywordsKey)
    }
    
    static func addPostSearchKeywords(_ keyword: String) {
        guard !UserSettings[.privacyModeEnabled] else {
            return
        }
        self.addValue(keyword, toStringArray: RecentlySearchedPostKeywordsKey)
    }
    
    static func removeSubredditSearchKeywords(_ keyword: String) {
        self.removeValue(keyword, ofStringArray: RecentlySearchedSubredditKeywordsKey)
    }
    
    static func removePostSearchKeywords(_ keyword: String) {
        self.removeValue(keyword, ofStringArray: RecentlySearchedPostKeywordsKey)
    }
    
    fileprivate static func addValue(_ value: String, toStringArray key: String) {
        var newResult = UserDefaults.standard.object(forKey: key) as? [String]
        if newResult != nil {
            if let currentIndex = newResult!.index(of: value) {
                newResult!.remove(at: currentIndex)
            }
        } else {
            newResult = [String]()
        }

        newResult?.insert(value, at: 0)
        newResult = newResult?.arrayWithLimit(5)
        
        UserDefaults.standard.set(newResult, forKey: key)
    }
    
    fileprivate static func removeValue(_ value: String, ofStringArray key: String) {
        var newResult = UserDefaults.standard.object(forKey: key) as? [String]
        if let index = newResult?.index(of: value) {
            newResult?.remove(at: index)
        }
        UserDefaults.standard.set(newResult, forKey: key)
    }
    
    // MARK: - Removing records
    
    static func clearSearchedSubredditKeywords() {
        clearStringArrayWithKey(RecentlySearchedSubredditKeywordsKey)
    }
    
    static func clearSearchedPostKeywords() {
        clearStringArrayWithKey(RecentlySearchedPostKeywordsKey)
    }
    
    fileprivate static func clearStringArrayWithKey(_ key: String) {
        UserDefaults.standard.set([String](), forKey: key)
    }
    
}
