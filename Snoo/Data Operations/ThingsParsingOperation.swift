//
//  ThingsParsingOperation.swift
//  Snoo
//
//  Created by Robin Speijer on 30-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

open class ThingsParsingOperation: DataOperation {
    
    fileprivate var requestOperation: RedditRequest
    open var managedObjectContext: NSManagedObjectContext
    
    open var things: [SyncObject]?
    
    init(request: RedditRequest, context: NSManagedObjectContext) {
        self.requestOperation = request
        self.managedObjectContext = context
        
        super.init()
    }
    
    override open func start() {
        super.start()
        
        var results = [SyncObject]()
        
        if let postedJSON = self.requestOperation.result?["json"] as? [String: AnyObject],
            let data = postedJSON["data"] as? [String: AnyObject],
            let things = data["things"] as? [[String: AnyObject]] {
            
                self.managedObjectContext.performAndWait({ () -> Void in
                    guard self.isCancelled == false else {
                        return
                    }
                    for thingDictionary in things {
                        guard self.isCancelled == false else {
                            break
                        }
                        if let childKind = thingDictionary["kind"] as? String,
                            let data = thingDictionary["data"] as? NSDictionary,
                            let itemClass = CollectionQuery.objectType(childKind) {
                                
                                var object: SyncObject! = nil
                                
                                do {
                                    object = try itemClass.objectWithDictionary(data, cache: nil, context: self.managedObjectContext)
                                    try object.parseObject(data, cache: nil)
                                    if object.objectID.isTemporaryID {
                                        try self.managedObjectContext.obtainPermanentIDs(for: [object])
                                    }
                                    results.append(object)
                                    
                                } catch {
                                    if let object = object {
                                        self.managedObjectContext.delete(object)
                                    }
                                }
                                
                        }
                        
                    }
                })
            
        }
        
        self.things = results
        
        self.finishOperation()
    }

}
