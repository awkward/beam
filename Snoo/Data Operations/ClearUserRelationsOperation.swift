//
//  ClearUserRelationsOperation.swift
//  Snoo
//
//  Created by Rens Verhoeven on 09-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import CoreData

/// This class performans a batch update to set all user related properties to their default value, this is useful when removing accounts or switching.
final class ClearUserRelationsOperation: DataOperation {
    
    var objectContext: NSManagedObjectContext! = DataController.shared.privateContext
    
    fileprivate var entityNames: [String] {
        return [Subreddit.entityName(), Multireddit.entityName()]
    }
    
    /**
     This function returns a dictionary with the attributes to update, the value is used as a last fallback when isOptional and defaultValue is not available
     
     - parameter name: The name of the entity of which the properties should be returned
     
     - returns: A dictionary of property descriptions and their fallback values
     */
    fileprivate func attributesToUpdateForEntityName(_ name: String) -> [NSAttributeDescription: NSObject]? {
        var attributesToUpdate = [NSAttributeDescription: NSObject]()
        let entityDescription = NSEntityDescription.entity(forEntityName: name, in: self.objectContext!)
        if name == Subreddit.entityName() {
            if let attributeDescription = entityDescription?.attributesByName["isOwner"] {
                attributesToUpdate[attributeDescription] = NSNumber(value: false as Bool)
            }
            if let attributeDescription = entityDescription?.attributesByName["isContributor"] {
                attributesToUpdate[attributeDescription] = NSNumber(value: false as Bool)
            }
            if let attributeDescription = entityDescription?.attributesByName["isSubscriber"] {
                attributesToUpdate[attributeDescription] = NSNumber(value: false as Bool)
            }
            if let attributeDescription = entityDescription?.attributesByName["isModerator"] {
                attributesToUpdate[attributeDescription] = NSNumber(value: false as Bool)
            }
        } else if name == Multireddit.entityName() {
            if let attributeDescription = entityDescription?.attributesByName["canEdit"] {
                attributesToUpdate[attributeDescription] = NSNumber(value: false as Bool)
            }
        } else if name == Post.entityName() {
            if let attributeDescription = entityDescription?.attributesByName["isSaved"] {
                attributesToUpdate[attributeDescription] = NSNumber(value: false as Bool)
            }
            if let attributeDescription = entityDescription?.attributesByName["isHidden"] {
                attributesToUpdate[attributeDescription] = NSNumber(value: false as Bool)
            }
        }
        return attributesToUpdate
    }
    
    fileprivate func predicateForEntityName(_ name: String) -> NSPredicate? {
        if name == Subreddit.entityName() {
            return NSPredicate(format: "NOT (identifier IN %@)", [Subreddit.frontpageIdentifier, Subreddit.allIdentifier])
        }
        return nil
    }
    
    override func start() {
        super.start()
        
        self.objectContext?.performAndWait { () -> Void in
            guard self.isCancelled == false else {
                return
            }
            for entityName in self.entityNames {
                guard self.isCancelled == false else {
                    break
                }
                if let attributesToUpdate = self.attributesToUpdateForEntityName(entityName) {
                    
                    let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                    request.predicate = self.predicateForEntityName(entityName)
                    do {
                        let objects = try self.objectContext.fetch(request)
                        for object in objects {
                            guard self.isCancelled == false else {
                                break
                            }
                            for (attributeDescription, fallbackValue) in attributesToUpdate {
                                guard self.isCancelled == false else {
                                    break
                                }
                                if let value = attributeDescription.defaultValue {
                                     object.setValue(value, forKey: attributeDescription.name)
                                } else if attributeDescription.isOptional {
                                    object.setValue(nil, forKey: attributeDescription.name)
                                } else {
                                    object.setValue(fallbackValue, forKey: attributeDescription.name)
                                }
                               
                            }
                        }
                    } catch {
                        //We don't care if an error happend
                    }
                    
                }
            }
        }
        
        self.finishOperation()
    }

}
