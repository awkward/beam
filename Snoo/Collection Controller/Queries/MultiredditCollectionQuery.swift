//
//  MultiredditCollectionQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 06-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class MultiredditCollectionQuery: CollectionQuery {

    override public var apiPath: String {
        return "api/multi/mine.json"
    }
    
    override var limit: Int {
        return 100
    }
    
    override var apiQueryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "expand_srs", value: "true"), URLQueryItem(name: "limit", value: "\(self.limit)")]
    }
    
    override public var requiresAuthentication: Bool {
        return true
    }
    
    override public func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        return nil
    }
    
    override public func collectionType() -> ObjectCollection.Type {
        return ObjectCollection.self
    }
    
}
