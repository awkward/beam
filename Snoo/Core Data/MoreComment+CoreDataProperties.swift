//
//  MoreComment+CoreDataProperties.swift
//  Snoo
//
//  Created by Rens Verhoeven on 29-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MoreComment {

    @NSManaged public var count: NSNumber?
    @NSManaged public var children: String?

}
