//
//  MessageCollectionQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class MessageCollectionQuery: CollectionQuery {
    
    public var messageBox = MessageBox.inbox
    
    override public var requiresAuthentication: Bool {
        return true
    }
    
    override var limit: Int {
        return 100
    }
    
    override var apiPath: String {
        return "/message/\(messageBox.rawValue)"
    }
    
    override var apiQueryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "limit", value: "\(self.limit)")]
    }
    
    override public func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        let superFetchRequest = super.fetchRequest()
        
        var predicates = [NSPredicate]()
        if let superPredicate = superFetchRequest?.predicate { predicates.append(superPredicate) }
        predicates.append(NSPredicate(format: "messageBox == %@", self.messageBox.rawValue))
        
        superFetchRequest?.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return superFetchRequest
    }
    
    override public func collectionType() -> ObjectCollection.Type {
        return MessageCollection.self
    }
    
    override class func objectType(_ kind: String) -> SyncObject.Type? {
        return Message.self
    }
    
}
