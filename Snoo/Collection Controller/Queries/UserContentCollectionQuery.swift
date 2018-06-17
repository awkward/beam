//
//  UserContentCollectionQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 25-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public enum UserContentType: String {
    case overview
    case submitted
    case comments
    case upvoted
    case downvoted
    case hidden
    case saved
    case gilded
}

public final class UserContentCollectionQuery: ContentCollectionQuery {

    open var userIdentifier: String
    open var userContentType: UserContentType = .submitted
    
    public init(userIdentifier: String) {
        self.userIdentifier = userIdentifier
        super.init()
    }
    
    override var apiPath: String {
        var username: String = ""
        DataController.shared.privateContext.performAndWait { () -> Void in
            do {
                if let user = try User.fetchObjectWithIdentifier(self.userIdentifier, context: DataController.shared.privateContext) as? User {
                    if let name = user.username {
                        username = name
                    } else {
                        username = "mine"
                    }
                } else {
                    username = "mine"
                }
            } catch {
                username = "mine"
            }
        }
        return "/user/\(username)/\(self.userContentType.rawValue)"
    }
    
    open override func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        let superFetchRequest = super.fetchRequest()
        
        var predicates = [NSPredicate]()
        if let superPredicate = superFetchRequest?.predicate { predicates.append(superPredicate) }
        predicates.append(NSPredicate(format: "userContentType = %@", userContentType.rawValue))
        predicates.append(NSPredicate(format: "user.identifier = %@", userIdentifier))
        
        superFetchRequest?.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return superFetchRequest
    }
    
    open override func collectionType() -> ObjectCollection.Type {
        return UserContentCollection.self
    }
    
}
