//
//  SubredditCollectionQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 25-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public final class SubredditsCollectionQuery: CollectionQuery {
    
    open var hideNSFWSubreddits = false
    
    open var userIdentifier: String?
    open var shouldPrepopulate = true
    open var shouldFetchDefaults = false
    
    public override init() {
        super.init()
    }
    
    override var limit: Int {
        return 100
    }
    
    override open var apiPath: String {
        if let query = self.searchKeywords, query.count > 0 {
            return "search.json"
        } else if self.collectionController?.authenticationController.isAuthenticated == true && self.shouldFetchDefaults == false {
            return "subreddits/mine/subscriber.json"
        } else {
            return "subreddits/default.json"
        }
    }
    
    override var apiQueryItems: [URLQueryItem]? {
        if let query = self.searchKeywords, query.count > 0 {
            return [URLQueryItem(name: "type", value: "sr"), URLQueryItem(name: "q", redditQuery: query, allowColon: false)]
        } else {
            return [URLQueryItem(name: "limit", value: "\(self.limit)")]
        }
    }
    
    open override func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        let superFetchRequest = super.fetchRequest()
        
        var predicates = [NSPredicate]()
        if let superPredicate = superFetchRequest?.predicate { predicates.append(superPredicate) }
        
        if let userIdentifier = userIdentifier {
            predicates.append(NSPredicate(format: "user.identifier == %@", userIdentifier))
        } else {
            predicates.append(NSPredicate(format: "user == nil"))
        }
        
        superFetchRequest?.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return superFetchRequest
    }
    
    open override func collectionType() -> ObjectCollection.Type {
        return SubredditCollection.self
    }
    
    override func prepopulate(_ context: NSManagedObjectContext) throws -> [SyncObject] {
        guard shouldPrepopulate else {
            return try super.prepopulate(context)
        }
        
        let frontpage = try Subreddit.frontpageSubreddit()
        
        let all = try Subreddit.allSubreddit()
        
        return try super.prepopulate(context) + [frontpage, all]
    }
    
    override func contentPredicates() -> [NSPredicate] {
        var predicates = super.contentPredicates()
        if self.hideNSFWSubreddits == true {
            predicates.append(NSPredicate(format: "isNSFW != true"))
        }
        return predicates
    }
    
    override func postProcessObjects(_ objects: NSOrderedSet) {
        super.postProcessObjects(objects)
        
    }
    
}
