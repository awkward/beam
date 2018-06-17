//
//  CollectionQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 11-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

open class CollectionQuery {
    
    weak var collectionController: CollectionController?
    /// Should be non-nil if this is a search query, otherwise it should be left nil.
    open var searchKeywords: String?
    open var contentPredicate: NSPredicate?
    open var sortType = CollectionSortType.none
    
    var apiPath: String {
        return ".json"
    }
    
    var apiQueryItems: [URLQueryItem]? {
        return nil
    }
    
    open var requiresAuthentication: Bool {
        return false
    }
    
    var limit: Int {
        return 25
    }
    
    open func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.collectionType().entityName())
        
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "sortType == %@", self.sortType.rawValue))
        if let searchKeywords = self.searchKeywords {
            predicates.append(NSPredicate(format: "searchKeywords == %@", searchKeywords))
        }
        if let contentPredicate = self.contentPredicate {
            predicates.append(NSPredicate(format: "contentPredicate == %@", contentPredicate.predicateFormat))
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.includesSubentities = false
        fetchRequest.shouldRefreshRefetchedObjects = true
        return fetchRequest
    }
    
    internal func contentPredicates() -> [NSPredicate] {
        var predicates = [NSPredicate]()
        if let contentPredicate = self.contentPredicate {
             predicates.append(contentPredicate)
        }
        return predicates
    }
    
    internal var compoundContentPredicate: NSCompoundPredicate? {
        if self.contentPredicates().count > 0 {
            return NSCompoundPredicate(andPredicateWithSubpredicates: self.contentPredicates())
        } else {
            return nil
        }
    }
    
    open func collectionType() -> ObjectCollection.Type {
        return ObjectCollection.self
    }
    
    /// This method could be used to prepopulate the database, using the given context.
    func prepopulate(_ context: NSManagedObjectContext) throws -> [SyncObject] {
        return [SyncObject]()
    }
    
    /// This method could be used to change properties to the objects specific to this collection query.
    func postProcessObjects(_ objects: NSOrderedSet) {
        
    }
    
    class func objectType(_ kind: String) -> SyncObject.Type? {
        return SyncObjectType(rawValue: kind)?.itemClass
    }
    
    public init() { }
}
