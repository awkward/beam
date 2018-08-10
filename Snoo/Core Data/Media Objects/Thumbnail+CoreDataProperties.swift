//
//  Thumbnail+CoreDataProperties.swift
//  Snoo
//
//  Created by Rens Verhoeven on 05/07/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//
//

import Foundation
import CoreData

extension Thumbnail {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Thumbnail> {
        return NSFetchRequest<Thumbnail>(entityName: "Thumbnail")
    }

    @NSManaged public var expirationDate: Date?
    @NSManaged public var pixelHeight: NSNumber?
    @NSManaged public var url: URL?
    @NSManaged public var pixelWidth: NSNumber?
    @NSManaged public var mediaObject: MediaObject?

}
