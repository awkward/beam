//
//  Subreddit+CoreDataProperties.swift
//  Snoo
//
//  Created by Robin Speijer on 09-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Subreddit {

    @NSManaged public var descriptionText: String?
    @NSManaged public var publicDescription: String?
    @NSManaged public var permalink: String?
    @NSManaged public var sectionName: String?
    @NSManaged public var title: String?
    @NSManaged public var displayName: String?
    @NSManaged public var headerImage: MediaObject?
    @NSManaged public var multireddits: NSSet?
    @NSManaged public var postCollections: NSSet?
    @NSManaged public var posts: NSSet?
    @NSManaged public var isNSFW: NSNumber?
    @NSManaged public var subscribers: NSNumber?
    @NSManaged public var lastVisitDate: Date?
    @NSManaged public var visibilityString: String?
    @NSManaged public var submissionTypeString: String?
    @NSManaged public var isOwner: NSNumber?
    @NSManaged public var isContributor: NSNumber?
    @NSManaged public var isModerator: NSNumber?
    @NSManaged public var isSubscriber: NSNumber?

}
