//
//  PostMetadata+CoreDataClass.swift
//  Beam
//
//  Created by Rens Verhoeven on 23/01/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import Foundation
import CoreData

/*
 This object is meant to hold all kinds of metadata for a post that should be stored for longer than the post it self.
 PostMetadata is hold into the database for 30 (or the time interval given in DataController.swift). While a post is only hold into the database for 24 hours (see DataController.swift)
 
 For metadata that should disappear with the post, see the metadata property on Post
 */
@objc(PostMetadata)
public class PostMetadata: NSManagedObject {
    
    open class func entityName() -> String {
        return "PostMetadata"
    }
    
    class func insertObject(_ context: NSManagedObjectContext) -> PostMetadata {
        let entityDescription = NSEntityDescription.entity(forEntityName: self.entityName(), in: context)!
        return PostMetadata(entity: entityDescription, insertInto: context)
    }
    
    public override func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)
        
        //If one of the values of the keys in the array changes, we update the expiration date so the post is kept in the database longer
        if self.entity.attributesByName.keys.contains(key) && key != "expirationDate" {
            self.expirationDate = NSDate(timeInterval: DataController.PostMetadataExpirationTimeOut, since: Date())
        }
    }

}
