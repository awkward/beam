//
//  MediaObject+CoreDataProperties.swift
//  beam
//
//  Created by Rens Verhoeven on 05/07/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//
//

import Foundation
import CoreData

extension MediaObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaObject> {
        return NSFetchRequest<MediaObject>(entityName: "MediaObject")
    }

    @NSManaged public var captionDescription: String?
    @NSManaged public var captionTitle: String?
    @NSManaged public var contentURL: URL?
    @NSManaged public var expirationDate: Date?
    @NSManaged public var pixelHeight: NSNumber?
    @NSManaged public var identifier: String?
    @NSManaged public var pixelWidth: NSNumber?
    @NSManaged public var content: Content?
    @NSManaged public var thumbnails: Set<Thumbnail>?
    @NSManaged internal var isNSFWNumber: NSNumber?

}

// MARK: Generated accessors for thumbnails
extension MediaObject {

    @objc(addThumbnailsObject:)
    @NSManaged public func addToThumbnails(_ value: Thumbnail)

    @objc(removeThumbnailsObject:)
    @NSManaged public func removeFromThumbnails(_ value: Thumbnail)

    @objc(addThumbnails:)
    @NSManaged public func addToThumbnails(_ values: NSSet)

    @objc(removeThumbnails:)
    @NSManaged public func removeFromThumbnails(_ values: NSSet)

}
