//
//  MoreComment.swift
//  Snoo
//
//  Created by Rens Verhoeven on 29-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import Foundation
import CoreData

open class MoreComment: Comment {

    open class override func entityName() -> String {
        return "MoreComment"
    }
    
    override class func insertObject(_ context: NSManagedObjectContext) -> SyncObject {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName(), in: context)!
        return MoreComment(entity: entityDescription, insertInto: context)
    }
    
    override func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        try super.parseObject(json, cache: cache)
        
        self.identifier = nil

        self.count = json["count"] as? NSNumber ?? self.count
        if let children = json["children"] as? NSArray {
            self.children = children.componentsJoined(by: ",")
        }
    }
    
    open override func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = super.redditDictionaryRepresentation()
        
        dictionary["count"] = self.count
        dictionary["children"] = self.children as AnyObject?
        
        return dictionary
    }

}
