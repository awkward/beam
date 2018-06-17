//
//  MultiredditQuery+Fetching.swift
//  Beam
//
//  Created by Rens Verhoeven on 27-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import Snoo
import CoreData

extension MultiredditQuery {
    
    class func fetchMultireddit(_ username: String, multiredditName: String, handler: @escaping ((_ multireddit: Multireddit?, _ error: Error?) -> Void)) {
        //Clean up any slashes from the name
        let cleanedMultiredditName = multiredditName.stringByRemovingStrings(["/m/", "m/", "/"])
        let cleanedUsername = username.stringByRemovingStrings(["/u/", "u/", "/user/", "user/", "/"])
        let subredditQuery = MultiredditQuery(displayName: cleanedMultiredditName, username: cleanedUsername)
        
        let collectionController = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        collectionController.query = subredditQuery
        collectionController.startInitialFetching { (collectionID: NSManagedObjectID?, error: Error?) -> Void in
            DispatchQueue.main.async {
                if error != nil {
                    handler(nil, error)
                }
                //TL;DR; Get the collectionID from the collectionController to make sure it's not released
                //At the end of the fetch method the CollectionController is released because nothing holds a strong reference to the CollectionController.
                //By using the CollectionController inside the closure, the closure holds a reference to the CollectionController until the closure is completed.
                if let collectionID = collectionController.collectionID, let collection = AppDelegate.shared.managedObjectContext.object(with: collectionID) as? ObjectCollection, let multireddit = collection.objects?.firstObject as? Multireddit {
                    handler(multireddit, nil)
                } else {
                    handler(nil, NSError.beamError(404, localizedDescription: "Multireddit '\(cleanedMultiredditName)' not found"))
                }
            }
        }
    }
}
