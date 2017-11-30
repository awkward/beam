//
//  SubredditCollection.swift
//  Snoo
//
//  Created by Robin Speijer on 24-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

@objc(SubredditCollection)
public final class SubredditCollection: ObjectCollection {
    
    override func configureQuery(_ query: CollectionQuery) {
        super.configureQuery(query)
        
        self.expirationDate = Date(timeIntervalSinceNow: DataController.SubredditTimeOut)
        
        if let query = query as? SubredditsCollectionQuery {
            if let userIdentifier = query.userIdentifier, let context = managedObjectContext {
                do {
                    user = try User.fetchObjectWithIdentifier(userIdentifier, context: context) as? User
                } catch {
                    NSLog("Could not load user for subreddit collection: \(error)")
                }
            }
        }
    }
    
    override class func entityName() -> String {
        return "SubredditCollection"
    }

}
