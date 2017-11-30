//
//  MessageCollectionQuery+Fetching.swift
//  Beam
//
//  Created by Rens Verhoeven on 15-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import Foundation
import Snoo

extension MessageCollectionQuery {

    public class func fetchUnreadMessages(_ completionHandler: @escaping (_ messages: [Message]?, _ error: Error?) -> Void) {
        let collectionController = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        let query = MessageCollectionQuery()
        query.contentPredicate = NSPredicate(format: "unread == %@", NSNumber(value: true))
        collectionController.query = query
        collectionController.startInitialFetching { (collectionID, error) -> Void in
            DispatchQueue.main.async {
                //TL;DR; Get the collectionID from the collectionController to make sure it's not released
                //At the end of the fetch method the CollectionController is released because nothing holds a strong reference to the CollectionController.
                //By using the CollectionController inside the closure, the closure holds a reference to the CollectionController until the closure is completed.
                if let collectionID = collectionController.collectionID, let collection = AppDelegate.shared.managedObjectContext.object(with: collectionID) as? ObjectCollection, let messages = collection.objects?.array as? [Message] {
                    completionHandler(messages, nil)
                } else {
                    completionHandler(nil, error)
                }
            }
        }
    }
    
}
