//
//  ContentCollectionQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 25-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

open class ContentCollectionQuery: CollectionQuery {
    
    open var hideReportedContent = true
    open var hideNSFWContent = false

    open var timeFrame = CollectionTimeFrame.defaultTimeFrame
    
    override var apiPath: String {
        return "\(self.sortType.rawValue).json"
    }
    
    open override func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        let superFetchRequest = super.fetchRequest()
        
        var predicates = [NSPredicate]()
        if let superPredicate = superFetchRequest?.predicate { predicates.append(superPredicate) }
        predicates.append(NSPredicate(format: "timeframe == %@", self.timeFrame.rawValue))
        
        superFetchRequest?.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return superFetchRequest
    }
    
    override func contentPredicates() -> [NSPredicate] {
        var predicates = super.contentPredicates()
        if self.hideReportedContent == true {
            predicates.append(NSPredicate(format: "hasBeenReported != true"))
        }
        if self.hideNSFWContent == true {
            //isContentNSFW only wroks on posts, but the ContentCollectionQuery can actually also contain comments
            predicates.append(NSPredicate(format: "(objectName BEGINSWITH[c] %@ AND isContentNSFW != YES) OR objectName BEGINSWITH[c] %@", "\(SyncObjectType.LinkType.rawValue)_", "\(SyncObjectType.CommentType.rawValue)_"))
        }
        return predicates
    }
    
    open override func collectionType() -> ObjectCollection.Type {
        return ContentCollection.self
    }

}
