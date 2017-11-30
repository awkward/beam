//
//  ContentCollection.swift
//  Snoo
//
//  Created by Robin Speijer on 26-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

open class ContentCollection: ObjectCollection {
    
    override func configureQuery(_ query: CollectionQuery) {
        super.configureQuery(query)
        
        if let query = query as? ContentCollectionQuery {
            self.timeframe = query.timeFrame.rawValue
        }
    }

    override class func entityName() -> String {
        return "ContentCollection"
    }

}
