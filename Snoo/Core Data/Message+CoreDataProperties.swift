//
//  Message+CoreDataProperties.swift
//  Snoo
//
//  Created by Robin Speijer on 17-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Message {

    @NSManaged public var messageBox: String?
    @NSManaged public var subject: String?
    @NSManaged public var unread: NSNumber?
    @NSManaged public var reference: Content?
    @NSManaged public var destination: String?
    @NSManaged public var postTitle: String?

}
