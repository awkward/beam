//
//  MediaDirectVideo+CoreDataProperties.swift
//  beam
//
//  Created by Rens Verhoeven on 05/07/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//
//

import Foundation
import CoreData

extension MediaDirectVideo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaDirectVideo> {
        return NSFetchRequest<MediaDirectVideo>(entityName: "MediaDirectVideo")
    }

    @NSManaged public var videoURL: URL?

}
