//
//  SaveOperation.swift
//  Snoo
//
//  Created by Robin Speijer on 09-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class SaveOperation: DataOperation {
    
    internal var objectContext: NSManagedObjectContext! = DataController.shared.privateContext
    
    fileprivate func objectContextFromDependency() -> NSManagedObjectContext? {
        let parseOperation = self.dependencies.first(where: { (operation) -> Bool in
            return operation is CollectionParsingOperation
        }) as? CollectionParsingOperation
        return parseOperation?.objectContext
    }
    
    override open func start() {
        super.start()
        
        if let dependentContext = objectContextFromDependency() {
            self.objectContext = dependentContext
        }
        
        do {
            try DataController.shared.saveContext(self.objectContext)
        } catch {
            self.error = error as NSError
        }
        
        self.finishOperation()
    }
    
}
