//
//  MediaImage+CoreDataProperties.swift
//  beam
//
//  Created by Rens Verhoeven on 05/07/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//
//

import Foundation
import CoreData

extension MediaImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaImage> {
        return NSFetchRequest<MediaImage>(entityName: "MediaImage")
    }

}
