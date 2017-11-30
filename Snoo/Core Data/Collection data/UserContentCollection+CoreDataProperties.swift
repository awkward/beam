//
//  UserContentCollection+CoreDataProperties.swift
//  Snoo
//
//  Created by Robin Speijer on 25-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension UserContentCollection {

    @NSManaged var userContentType: String?
    @NSManaged var user: User?

}
