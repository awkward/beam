//
//  MessageCollection.swift
//  Snoo
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public final class MessageCollection: ObjectCollection {

    override func configureQuery(_ query: CollectionQuery) {
        super.configureQuery(query)
        
        if let query = query as? MessageCollectionQuery {
            self.messageBox = query.messageBox.rawValue
        }
    }
    
    override class func entityName() -> String {
        return "MessageCollection"
    }

}
