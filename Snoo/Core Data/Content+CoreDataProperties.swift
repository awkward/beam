//
//  Content+CoreDataProperties.swift
//  Snoo
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

extension Content {
    
    @NSManaged public var content: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var downvoteCount: NSNumber?
    @NSManaged public var gildCount: NSNumber?
    @NSManaged public var permalink: String?
    @NSManaged public var score: NSNumber?
    
    @NSManaged public var upvoteCount: NSNumber?
    @NSManaged public var voteStatus: NSNumber?
    @NSManaged public var author: String?
    @NSManaged public var authorFlairText: String?
    @NSManaged public var mediaObjects: NSOrderedSet?
    @NSManaged public var referencedByMessages: NSSet?
    
    //Required properties with a default value
    @NSManaged public var scoreHidden: NSNumber //Default: No
    @NSManaged public var isSaved: NSNumber //Default: No
    @NSManaged public var stickied: NSNumber //Default: No
    @NSManaged public var archived: NSNumber //Default: No
    @NSManaged public var locked: NSNumber //Default: No
}
