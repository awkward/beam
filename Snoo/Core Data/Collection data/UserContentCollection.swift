//
//  UserContentCollection.swift
//  Snoo
//
//  Created by Robin Speijer on 25-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public final class UserContentCollection: ContentCollection {

    override func configureQuery(_ query: CollectionQuery) {
        super.configureQuery(query)
        
        if let query = query as? UserContentCollectionQuery, let context = managedObjectContext {
            do {
                self.user = try User.fetchObjectWithIdentifier(query.userIdentifier, context: context) as? User
            } catch {
                NSLog("Could noet fetch user with identifier %@ in UserContentCollection", query.userIdentifier)
            }
            
            self.userContentType = query.userContentType.rawValue
        }
    }
    
    override class func entityName() -> String {
        return "UserContentCollection"
    }

}
