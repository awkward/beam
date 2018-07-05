//
//  CollectionParsingOperation.swift
//  Snoo
//
//  Created by Robin Speijer on 09-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class CollectionParsingOperation: DataOperation {
    
    // MARK: - Properties
    
    public var objectContext: NSManagedObjectContext! = DataController.shared.privateContext
    
    // Input
    
    /// The source that that needs to be parsed
    internal var data: NSDictionary?
    
    /// The query for which this response is parsed
    public var query: CollectionQuery
    
    /// In case this property is set to true, the operation will delete existing objects in the collection that are not present in the data dictionary
    var shouldDeleteMissingMemoryObjects = false
    
    // Output
    
    /// The resulting parsed object collection (in the private object context)
    public var objectCollection: ObjectCollection?
    
    public var filteredObjects: Set<NSManagedObject>?
    
    /// The last object identifier, to be used for a new next request
    var after: String?
    
    /// The first object identifier, to be used for a new previous request
    var before: String?
    
    var requestOperation: RedditRequest? {
        let requestOperation = self.dependencies.first(where: { (operation) -> Bool in
            return operation is RedditRequest
        })
        return requestOperation as? RedditRequest
    }
    
    // MARK: - Lifecycle
    
    init(query: CollectionQuery) {
        self.query = query
        super.init()
    }
    
    override open func start() {
        super.start()
        
        if self.data != nil {
            self.objectContext?.performAndWait { () -> Void in
                guard self.isCancelled == false else {
                    return
                }
                do {
                    try self.parseObjects(self.data!, context: self.objectContext!)
                    self.objectCollection!.configureQuery(self.query)
                    if self.objectCollection!.objectID.isTemporaryID {
                        try self.objectContext?.obtainPermanentIDs(for: [self.objectCollection!])
                    }
                    
                    if let objects = self.objectCollection!.objects {
                        self.query.postProcessObjects(objects)
                    }
                } catch {
                    self.error = error
                }
            }
        } else if let requestOperation = self.requestOperation, let data = requestOperation.result {
            self.data = data
            self.objectContext?.performAndWait { () -> Void in
                guard self.isCancelled == false else {
                    return
                }
                do {
                    try self.parseObjects(self.data!, context: self.objectContext!)
                    self.objectCollection!.configureQuery(self.query)
                    if self.objectCollection!.objectID.isTemporaryID {
                        try self.objectContext?.obtainPermanentIDs(for: [self.objectCollection!])
                    }
                    
                    if let objects = self.objectCollection!.objects {
                        self.query.postProcessObjects(objects)
                    }
                } catch {
                    self.error = error
                }
            }
        } else if let requestOperation = self.requestOperation, requestOperation.isCancelled == true {
            self.cancelOperation()
        } else {
            if self.requestOperation == nil {
                self.error = NSError.snooError(500, localizedDescription: "No reddit request as dependency to parse")
            } else {
                self.error = NSError.snooError(500, localizedDescription: "No result as dependency to parse")
            }
        }
        
        self.finishOperation()
        
    }
    
    // MARK: - Parsing
    
    /// Parse all objects in the given Reddit API json response, in the given object context. This will set the objectCollection property and makes sure it is set. Otherwise, an error will be thrown.
    internal func parseObjects(_ json: AnyObject, context: NSManagedObjectContext) throws {
        
        if self.objectCollection == nil {
            self.objectCollection = try self.fetchLocalCollection(self.query)
            
            if self.objectCollection == nil {
                self.objectCollection = self.insertCollectionWithType(query.collectionType(), context: self.objectContext!)
            }
        }
        
        guard objectCollection != nil else {
            throw NSError.snooError(500, localizedDescription: "Could not create object collection while parsing listing")
        }
        
        self.objectCollection!.lastRefresh = Date()
        self.objectCollection!.sortType = query.sortType.rawValue
        
        if let jsonDict = json as? NSDictionary, let data = jsonDict["data"] as? NSDictionary {
            try self.parseRootData(data, inCollection: self.objectCollection!)
        } else if let jsonArray = json as? NSArray {
            let lastRootObject = jsonArray[jsonArray.count - 1]
            try self.parseRootData(lastRootObject as! NSDictionary, inCollection: self.objectCollection!)
        }
        
        // don't cache empty collections
        if self.objectCollection!.objects?.count ?? 0 == 1 {
            self.objectCollection?.expirationDate = nil
        }
        
    }
    
    func parseListing(_ data: NSDictionary) throws -> NSOrderedSet {
        let cache = NSCache<NSString, NSManagedObjectID>()
        
        if let children = data["children"] as? NSArray {
            
            var fullNames = [String]()
            for child in children {
                if let childInfo = child as? NSDictionary, let childData = childInfo["data"] as? NSDictionary, let fullName = childData["name"] as? String {
                    fullNames.append(fullName)
                }
            }
            
            var types = [SyncObjectType]()
            for fullName in fullNames {
                if let identifierAndType = try? SyncObject.identifierAndTypeWithObjectName(fullName), let type = identifierAndType?.type, !types.contains(type) {
                    types.append(type)
                }
            }
            
            var fetchRequests = [NSFetchRequest<SyncObject>]()
            for type in types {
                let identifiers = fullNames.filter({ $0.hasPrefix(type.rawValue) }).map({ return SyncObject.identifierWithObjectName($0)! })
                if identifiers.count > 0 {
                    let entityName = type.itemClass.entityName()
                    let fetchRequest = NSFetchRequest<SyncObject>(entityName: entityName)
                    fetchRequest.resultType = NSFetchRequestResultType()
                    fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
                    fetchRequests.append(fetchRequest)
                }
            }
            
            var objectPerFullName = [String: SyncObject]()
            for fetchRequest in fetchRequests {
                let objects = try self.objectContext.fetch(fetchRequest)
                for object in objects {
                    objectPerFullName[object.objectName!] = object
                }

            }
            
            let childObjects = NSMutableOrderedSet(capacity: children.count)
            
            for (childIdx, child) in children.enumerated() {
                guard let childDictionary = child as? NSDictionary else {
                    continue
                }
                if childDictionary["kind"] as? String == "Listing" && childIdx == children.count - 1 {
                    if let data = childDictionary["data"] as? NSDictionary {
                        return try self.parseListing(data)
                    }
                    
                    throw NSError(domain: SnooErrorDomain, code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected server response: listing data is nil"])
                }
                
                // we have the kind enum and the itemClass as separate variabled, because we can have a message that references to for example a post. In this case kind is post, while itemClass is a message.
                if let childObject = try self.parseChild(child as! NSDictionary, cache: cache, objectsCache: objectPerFullName) {
                    childObjects.add(childObject)
                }
                
            }
            
            return childObjects
        }
        
        throw NSError(domain: SnooErrorDomain, code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected server response: listing data is nil"])
    }
    
    fileprivate func isChildMoreType(_ child: NSDictionary) -> Bool? {
        if let childKind = child["kind"] as? String,
            let kind = SyncObjectType(rawValue: childKind) {
            return kind == SyncObjectType.MoreType
        }
        return nil
    }
    
    fileprivate func parseMoreChild(_ moreChild: NSDictionary) -> (count: Int, parentObject: SyncObject?)? {
        if let data = moreChild["data"] as? NSDictionary,
            let count = data["count"] as? NSNumber {
                
                do {
                    if let parentFullName = data["parent_id"] as? String,
                        let (parentIdentifier, parentType) = try SyncObject.identifierAndTypeWithObjectName(parentFullName),
                        let parent = try CollectionQuery.objectType(parentType.rawValue)?.fetchObjectWithIdentifier(parentIdentifier, context: self.objectContext) as? InteractiveContent {
                            return (count.intValue, parent)
                    }
                } catch {
                    return (count.intValue, nil)
                }
        }
        
        return nil
    }
    
    fileprivate func parseChild(_ child: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?, objectsCache: [String: SyncObject]? = nil) throws -> SyncObject? {
        
        if let childKind = child["kind"] as? String,
            let kind = SyncObjectType(rawValue: childKind),
            let data = child["data"] as? NSDictionary,
            let itemClass = CollectionQuery.objectType(childKind) {
            
            var object: SyncObject!
            if let objectsCache = objectsCache {
                if let fullName = data["name"] as? String, let existingObject = objectsCache[fullName] {
                    object = existingObject
                } else {
                    object = try itemClass.objectWithDictionary(data, cache: cache, context: self.objectContext, checkForExisting: false)
                }
            } else {
                object = try itemClass.objectWithDictionary(data, cache: cache, context: self.objectContext)
            }
            
            do {
                try object.parseObject(data, cache: cache)
                
                if let referenceObject = object as? Content, kind != SyncObjectType.MessageType && self.query is MessageCollectionQuery {
                    
                    let message = try Message.objectWithDictionary(data, cache: cache, context: self.objectContext) as! Message
                    try message.parseObject(data, cache: cache)
                    message.reference = referenceObject
                    
                    if message.objectID.isTemporaryID {
                        try self.objectContext.obtainPermanentIDs(for: [message])
                    }
                    
                    return message
                }
                
                if object.objectID.isTemporaryID {
                    try self.objectContext?.obtainPermanentIDs(for: [object])
                }
                
                return object
            } catch {
                self.objectContext?.delete(object)
                throw error
            }
                
        } else {
            return nil
        }
        
    }
    
    fileprivate func parseRootData(_ data: NSDictionary, inCollection collection: ObjectCollection) throws {
        
        self.after = data["after"] as? String
        self.before = data["before"] as? String
        
        let parsingContext: NSManagedObjectContext! = DataController.shared.privateContext
        
        // Parse objects and prepopulate with data given by the query.
        var parsedObjects = collection.objects?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        
        var shouldUnionSet = true
        if let collectionRequest = self.requestOperation as? RedditCollectionRequest {
            shouldUnionSet = collectionRequest.after != nil
        }
        
        // Listing
        if data["children"] != nil {
            
            let responseObjects = try self.parseListing(data)
            
            if let oldObjects = collection.objects?.array as? [SyncObject], self.shouldDeleteMissingMemoryObjects {
                for oldObject in oldObjects {
                    if !responseObjects.contains(oldObject) {
                        parsedObjects.remove(oldObject)
                    }
                }
            }
            
            if shouldUnionSet {
                parsedObjects.union(responseObjects)
            } else {
                parsedObjects = responseObjects.mutableCopy() as! NSMutableOrderedSet
            }
            
            // Single Subreddit object
        } else if query is MultiredditQuery {
            let parsedObject = try Multireddit.objectWithDictionary(data, cache: nil, context: parsingContext) as! Multireddit
            try parsedObject.parseObject(data, cache: nil)
            if shouldUnionSet {
                parsedObjects.union(NSOrderedSet(object: parsedObject))
            } else {
                parsedObjects = NSOrderedSet(object: parsedObject).mutableCopy() as! NSMutableOrderedSet
            }
        } else if query is SubredditQuery {
            let parsedObject = try Subreddit.objectWithDictionary(data, cache: nil, context: parsingContext) as! Subreddit
            try parsedObject.parseObject(data, cache: nil)
            if shouldUnionSet {
                parsedObjects.union(NSOrderedSet(object: parsedObject))
            } else {
                parsedObjects = NSOrderedSet(object: parsedObject).mutableCopy() as! NSMutableOrderedSet
            }
        }
        
        // Prepopulate
        parsedObjects.addObjects(from: try self.query.prepopulate(parsingContext))
        
        // Filter
        if let predicate = self.query.compoundContentPredicate {
            let allObjects = parsedObjects.set as? Set<NSManagedObject>
            parsedObjects.filter(using: predicate)
            let distraction = (allObjects?.subtracting(parsedObjects.array as? [NSManagedObject] ?? [NSManagedObject]())) ?? Set<NSManagedObject>()
            self.filteredObjects = distraction
        }
        
        collection.objects = parsedObjects
    }
    
    fileprivate func fetchLocalCollection(_ query: CollectionQuery) throws -> ObjectCollection? {
        if let fetchRequest = query.fetchRequest() {
            return try self.objectContext.fetch(fetchRequest).first as? ObjectCollection
        }
        return nil
    }
    
    func insertCollectionWithType(_ type: ObjectCollection.Type, context: NSManagedObjectContext) -> ObjectCollection? {
        let collectionEntity = NSEntityDescription.entity(forEntityName: type.entityName(), in: context)
        
        if let entity = collectionEntity {
            return ObjectCollection(entity: entity, insertInto: context)
        } else {
            return nil
        }
    }
    
}
