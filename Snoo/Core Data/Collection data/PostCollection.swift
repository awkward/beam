//
//  PostCollection.swift
//  Snoo
//
//  Created by Robin Speijer on 10-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

@objc(PostCollection)
public final class PostCollection: ContentCollection {
    
    override func configureQuery(_ query: CollectionQuery) {
        super.configureQuery(query)
        
        if let query = query as? PostCollectionQuery {
            if self.managedObjectContext == query.subreddit?.managedObjectContext {
                self.subreddit = query.subreddit
            } else if let subredditID = query.subreddit?.objectID {
                self.subreddit = self.managedObjectContext?.object(with: subredditID) as? Subreddit
            }
        }
    }
    
    override class func entityName() -> String {
        return "PostCollection"
    }
    
}
