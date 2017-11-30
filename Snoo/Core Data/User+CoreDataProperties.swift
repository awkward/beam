//
//  User+CoreDataProperties.swift
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

extension User {

    @NSManaged public var commentKarmaCount: NSNumber?
    @NSManaged public var linkKarmaCount: NSNumber?
    @NSManaged public var modhash: String?
    @NSManaged public var registrationDate: Date?
    @NSManaged public var username: String?
    
    @NSManaged public var contentCollections: NSSet?
    @NSManaged public var relatedSubredditCollection: SubredditCollection?
    
    //Required properties with default values
    @NSManaged public var isGold: NSNumber //Default: No
    @NSManaged public var isOver18: NSNumber //Default: No
    @NSManaged public var hasModMail: NSNumber //Default: No
    @NSManaged public var hasMail: NSNumber //Default: No

}
