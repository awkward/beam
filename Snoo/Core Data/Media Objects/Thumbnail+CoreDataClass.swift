//
//  Thumbnail+CoreDataClass.swift
//  Snoo
//
//  Created by Rens Verhoeven on 05/07/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//
//

import Foundation
import CoreData

public class Thumbnail: NSManagedObject {

    public class func entityName() -> String {
        return "Thumbnail"
    }
    
    public var pixelSize: CGSize {
        set {
            self.pixelHeight = NSNumber(value: Int(newValue.height))
            self.pixelWidth = NSNumber(value: Int(newValue.width))
        }
        get {
            return CGSize(width: self.pixelWidth?.intValue ?? 0, height: self.pixelHeight?.intValue ?? 0)
        }
    }
    
}
