//
//  ObjectCollection+CoreData.swift
//  Snoo
//
//  Created by Robin Speijer on 24-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

extension ObjectCollection {
    
    @NSManaged public var sortType: String?
    @NSManaged public var objects: NSOrderedSet?
    @NSManaged public var lastRefresh: Date?
    @NSManaged public var searchKeywords: String?
    @NSManaged public var expirationDate: Date?
    @NSManaged public var isBookmarked: NSNumber?
    @NSManaged public var contentPredicate: String?
    
}
