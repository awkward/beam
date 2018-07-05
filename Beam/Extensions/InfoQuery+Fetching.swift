//
//  InfoQuery+Fetching.swift
//  Beam
//
//  Created by Rens Verhoeven on 12-07-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import Foundation
import Snoo
import CoreData

extension InfoQuery {
    
    class func fetch(_ fullName: String, handler: @escaping ((_ object: SyncObject?, _ error: Error?) -> Void)) {
        let query = InfoQuery(fullName: fullName)
        let collectionController = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        collectionController.query = query
        collectionController.startInitialFetching { (collectionID: NSManagedObjectID?, error: Error?) -> Void in
            DispatchQueue.main.async {
                if error != nil {
                    handler(nil, error)
                }
                //TL;DR; Get the collectionID from the collectionController to make sure it's not released
                //At the end of the fetch method the CollectionController is released because nothing holds a strong reference to the CollectionController.
                //By using the CollectionController inside the closure, the closure holds a reference to the CollectionController until the closure is completed.
                if let collectionID = collectionController.collectionID, let collection = AppDelegate.shared.managedObjectContext.object(with: collectionID) as? ObjectCollection, let subreddit = collection.objects?.firstObject as? SyncObject {
                    handler(subreddit, nil)
                } else {
                    handler(nil, NSError.beamError(404, localizedDescription: "Object '\(fullName)' not found"))
                }
            }
        }
    }
    
}
