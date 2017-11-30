//
//  ObjectQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 11-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class ObjectNamesQuery: CollectionQuery {
    
    open let fullNames: [String]
    
    public init(fullNames: [String]) {
        self.fullNames = fullNames
        super.init()
    }
    
    override var apiPath: String {
        let joinedFullNames = fullNames.joined(separator: ",")
        return "by_id/\(joinedFullNames).json"
    }

    open override func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        return nil
    }
    
}
