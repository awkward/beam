//
//  Thumbnail+CoreDataProperties.swift
//  Snoo
//
//  Created by Robin Speijer on 23-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Thumbnail {

    @NSManaged public var urlString: String?
    @NSManaged public var width: NSNumber?
    @NSManaged public var height: NSNumber?
    @NSManaged public var mediaObject: MediaObject?
    @NSManaged public var expirationDate: Date?

}
