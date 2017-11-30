//
//  MultiredditQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 26-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class MultiredditQuery: CollectionQuery {
    
    let username: String
    let displayName: String
    
    public init(displayName: String, username: String) {
        self.username = username
        self.displayName = displayName
        super.init()
    }
    
    override var apiPath: String {
        return "api/multi/user/\(self.username)/m/\(displayName.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))"
    }
    
    override var apiQueryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "expand_srs", value: "true")]
    }
    
    open override func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        return nil
    }

}
