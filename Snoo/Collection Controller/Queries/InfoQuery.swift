//
//  InfoQuery.swift
//  Snoo
//
//  Created by Rens Verhoeven on 04-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class InfoQuery: CollectionQuery {
    
    open let fullName: String
    
    public init(fullName: String) {
        self.fullName = fullName
        super.init()
    }
    
    override var apiPath: String {
        return "api/info.json"
    }
    
    override var apiQueryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "id", value: self.fullName)]
    }
    
    open override func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        return nil
    }
    
}
