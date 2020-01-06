//
//  MediaAnimatedGIF+CoreDataProperties.swift
//  beam
//
//  Created by Rens Verhoeven on 05/07/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//
//

import Foundation
import CoreData

extension MediaAnimatedGIF {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaAnimatedGIF> {
        return NSFetchRequest<MediaAnimatedGIF>(entityName: "MediaAnimatedGIF")
    }

    @NSManaged public var videoURL: URL?

}
