//
//  SyncObject.swift
//  Snoo
//
//  Created by Robin Speijer on 10-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public enum SyncObjectType: String {
    case CommentType = "t1"
    case AccountType = "t2"
    case LinkType = "t3"
    case MessageType = "t4"
    case SubredditType = "t5"
    case AwardType = "t6"
    case PromoCampaignType = "t8"
    case MoreType = "more"
    case LabeledMultiType = "LabeledMulti"
    
    var itemClass: SyncObject.Type {
        switch self {
        case .CommentType:
            return Comment.self
        case .LinkType:
            return Post.self
        case .SubredditType:
            return Subreddit.self
        case .LabeledMultiType:
            return Multireddit.self
        case .MessageType:
            return Message.self
        case .MoreType:
            return MoreComment.self
        default:
            return SyncObject.self
        }
    }
}

@objc(SyncObject)
open class SyncObject: NSManagedObject {
    
    /**
    This method always returns a SyncObject with the given Reddit API dictionary. It either fetches the existing one using the identifier property or inserts a new one if it doesn't exist yet.

    - parameter dictionary: The Reddit API dictionary. It should always contain an identifying "id" or "name" property.
    - parameter cache: A cache to prevent doing unneeded work. If multiple objects need the same object, it can be retreived from cache the second time instead of fetching the Core Data database.
    - parameter context: The Core Data context to use for fetching or inserting objects.
    - parameter checkForExisting: If the method should check for an existing object before creating a new one. Defaults to true
     
    - returns: The existing or new SyncObject. It only contains the identifier property, other properties still need to be parsed using the parseObject() method.
    */
    open class func objectWithDictionary(_ dictionary: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?, context: NSManagedObjectContext, checkForExisting: Bool = true) throws -> SyncObject {
        
        var identifier: String?
        if let dictId = dictionary["id"] as? String {
            identifier = dictId
        } else if let name = dictionary["name"] as? String, let identifierFromName = SyncObject.identifierWithObjectName(name) {
            identifier = identifierFromName
        } else if let name = dictionary["name"] as? String {
            identifier = name
        }
        
        if let identifier = identifier {
            return try objectWithIdentifier(identifier, cache: cache, context: context)
        } else {
            throw NSError(domain: "Snoo", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unexpected Reddit response"])
        }
    }
    
    /**
    This method always returns a SyncObject with the given identifier. It either fetches the existing one or inserts a new one if it doesn't exist yet.
    
    - parameter identifier: The identifier of the object to retreive. This is the identifier without the kind pre-fix. Use `identifierAndTypeWithObjectName:` to get the identifier
    - parameter cache: A cache to prevent doing unneeded work. If multiple objects need the same object, it can be retreived from cache the second time instead of fetching the Core Data database.
    - parameter context: The Core Data context to use for fetching or inserting objects.
    - parameter checkForExisting: If the method should check for an existing object before creating a new one. Defaults to true
    
    - returns: The existing or new SyncObject. It only contains the identifier property, other properties still need to be parsed using the parseObject() method.
    */
    open class func objectWithIdentifier(_ identifier: String, cache: NSCache<NSString, NSManagedObjectID>?, context: NSManagedObjectContext, checkForExisting: Bool = true) throws -> SyncObject {
        guard identifier.count > 0 else {
            throw NSError(domain: "nl.madeawkward.snoo", code: 500, userInfo: [NSLocalizedDescriptionKey: "SyncObject must have an identifier"])
        }
        
        /*
        We have the following strategy here:
        1:  Check the cache whether it contains an NSManagedObjectID related to the identifier. If so, return the corresponding NSManagedObject.
        2:  Fetch the database for the identifier and return the result.
        3:  Insert the object and return the newly created one.
        */
        
        //Only do these checks if we sould check for an existing object
        if checkForExisting {
            // Strategy 1: Get it from cache
            if let objectId = cache?.object(forKey: self.cacheIdentifier(identifier)), let object = context.object(with: objectId) as? SyncObject {
                return object
            }
            
            // Strategy 2: Fetch it manually (and add to cache so we don't need to fetch the next time)
            if let fetchedObject = try fetchObjectWithIdentifier(identifier, context: context) {
                cache?.setObject(fetchedObject.objectID, forKey: self.cacheIdentifier(identifier))
                return fetchedObject
            }
        }
        
        // Strategy 3: Insert it
        let insertedObject = insertObject(context)
        try insertedObject.validateForInsert()
        insertedObject.identifier = identifier
        // The inserted object will be parsed later. This method just asks for the instance to parse the data into. If the empty object is used for displaying in the UI, something is going wrong.
        // The temporary ObjectID will be used to identify this inserted object. This is the reason why the cache should only be used within the parse method.
        cache?.setObject(insertedObject.objectID, forKey: self.cacheIdentifier(identifier))
        return insertedObject
    }
    
    /**
    Fetches an object with the given identifier from the given object context. If the object does not exist, the method will return nil.
    - parameter identifier: The identifier of the object to fetch.
    - returns: The object or nil if it does not exist.
    */
    open class func fetchObjectWithIdentifier(_ identifier: String, context: NSManagedObjectContext) throws -> SyncObject? {
        let fetchRequest = NSFetchRequest<SyncObject>(entityName: self.entityName())
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        fetchRequest.fetchLimit = 1
        let results = try context.fetch(fetchRequest)
        if let result = results.first {
            return result
        }
        return nil
    }
    
    /// Creates a new SyncObject and inserts it into the given Core Data context.
    class func insertObject(_ context: NSManagedObjectContext) -> SyncObject {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName(), in: context)!
        return SyncObject(entity: entityDescription, insertInto: context)
    }
    
    /// A string that can be used in a parsing cache to identify an object with the object identifier. This method adds entity information to the used identifier, because objects of different entities could have the same identifiers.
    class func cacheIdentifier(_ identifier: String) -> NSString {
        return "\(entityName())-\(identifier)" as NSString
    }
    
    /// The name of the entity in the Core Data model.
    open class func entityName() -> String {
        return "SyncObject"
    }
    
    /// The Reddit object type of this object. We use this separate object because the Reddit API can be inconsistent. It can for example return a "load more" placeholder as a subreddit. This object type can be trusted.
    var objectType: SyncObjectType? {
        switch self {
        case is Comment:
            return .CommentType
        case is User:
            return .AccountType
        case is Post:
            return .LinkType
        case is Subreddit:
            return .SubredditType
        case is Message:
            return .MessageType
        default:
            return nil
        }
    }
    
    /// The full name of the object. This is defined by Reddit as <type identifier>_<object identifier>. It can be used in ObjectNamesQuery.
    @objc open var objectName: String? {
        if let objectType = self.objectType, let identifier = self.identifier {
            return "\(objectType.rawValue)_\(identifier)"
        } else {
            return self.identifier
        }
    }
    
    /**
     Creates and returns a dictionary with the keys according to the reddit API. These functions can be reused lated to send reddit objects to various API's
     
     - returns: A dictionary containing all possible keys following the reddit API naming
     */
    open func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary["name"] = self.objectName
        dictionary["identifier"] = self.identifier
        return dictionary
    }
    
    /**
    Parses the given Reddit API dictionary into the receiver.
    - parameter json: The Reddit API dictionary
    - parameter cache: A cache to prevent double work. For parsing, this will be used for setting relationships.
    */
    func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        if self.hasBeenReported == false {
            self.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
        }
        self.lastRefreshDate = Date()
    }
    
    /**
    Parses an object type and identifier from a Reddit 'fullname'.
    */
    open class func identifierAndTypeWithObjectName(_ name: String) throws -> (identifier: String, type: SyncObjectType)? {
        let regex: NSRegularExpression = try NSRegularExpression(pattern: "(.*)_(.*)", options: [])
        if let match: NSTextCheckingResult = regex.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)), match.numberOfRanges == 3 {
            let identifier: NSString = (name as NSString).substring(with: match.range(at: 2)) as NSString
            let kind: NSString = (name as NSString).substring(with: match.range(at: 1)) as NSString
            if let type: SyncObjectType = SyncObjectType(rawValue: kind as String) {
                return (identifier: identifier as String, type: type)
            }
        }
        let userInfo: [String: String] = [NSLocalizedDescriptionKey: "Object name '\(name)' has an incorrect format."]
        throw NSError(domain: SnooErrorDomain, code: 500, userInfo: userInfo)
    }
    
    /// Parses the identifier for an object given the objects 'fullname'.
    open class func identifierWithObjectName(_ name: String) -> String? {
        do {
            let object = try identifierAndTypeWithObjectName(name)
            return object?.identifier
        } catch {
            NSLog("reddit object with name '%@' could not be parsed to an identifier.", name)
        }
        
        return nil
    }

}
