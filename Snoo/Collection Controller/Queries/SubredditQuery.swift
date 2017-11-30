//
//  ObjectTitleQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 14-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class SubredditQuery: CollectionQuery {
    
    let displayName: String
    
    public init(displayName: String) {
        self.displayName = displayName
        super.init()
    }
    
    override var apiPath: String {
        return "r/\(displayName.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))/about.json"
    }
    
    open override func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        return nil
    }
    
}
