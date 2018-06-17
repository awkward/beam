//
//  SyncObject+CoreDataProperties.swift
//  Snoo
//
//  Created by Robin Speijer on 24-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

extension SyncObject: MetadataHandling {
    @NSManaged var expirationDate: Date?
    @NSManaged public var identifier: String?
    @NSManaged public var lastRefreshDate: Date?
    @NSManaged public var collections: NSSet?
    @NSManaged public var isBookmarked: NSNumber
    @NSManaged public var order: NSNumber
    @NSManaged public var metadata: NSDictionary?
    @NSManaged public var hasBeenReported: NSNumber
}
