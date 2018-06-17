//
//  ClearDataOperation.swift
//  Snoo
//
//  Created by Robin Speijer on 09-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

final class BatchDeleteOperation: DataOperation {
    
    var objectContext: NSManagedObjectContext?
    var onlyClearExpiredContent = true
    var includesUser = false
    
    fileprivate var entityNames: [String] {
        if self.includesUser {
            return [SyncObject.entityName(), ObjectCollection.entityName(), MediaObject.entityName(), Thumbnail.entityName(), PostMetadata.entityName()]
        } else {
            return [Content.entityName(), ObjectCollection.entityName(), Subreddit.entityName(), MediaObject.entityName(), Thumbnail.entityName(), PostMetadata.entityName()]
        }
    }
    
    override func start() {
        super.start()
        
        if self.objectContext == nil {
            self.objectContext = DataController.shared.privateContext
        }
        
        self.objectContext!.performAndWait { () -> Void in
            guard self.isCancelled == false else {
                return
            }
            do {
                for fetchRequest in self.fetchRequests {
                    guard self.isCancelled == false else {
                        break
                    }
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    deleteRequest.resultType = .resultTypeCount
                    if let result = try self.objectContext!.execute(deleteRequest) as? NSBatchDeleteResult, let deletedCount = result.result as? Int {
#if DEBUG
                        print("Result of expiration delete (\(fetchRequest.entityName!)): \(deletedCount)")
#endif
                    }
                    
                }
            } catch {
                self.error = error
            }
        }
        
        self.finishOperation()
    }
    
    func expirationDate(for entityName: String) -> NSDate {
        if entityName == Subreddit.entityName() || entityName == Multireddit.entityName() {
            return NSDate(timeIntervalSinceNow: DataController.SubredditTimeOut * -1)
        } else if entityName == PostMetadata.entityName() {
            return NSDate(timeIntervalSinceNow: DataController.PostMetadataExpirationTimeOut * -1)
        } else {
            return NSDate(timeIntervalSinceNow: DataController.ExpirationTimeOut * -1)
        }
    }
    
    var fetchRequests: [NSFetchRequest<NSFetchRequestResult>] {
        return self.entityNames.map({ (entityName: String) -> NSFetchRequest<NSFetchRequestResult> in
            
            //Thumbnail, MediaObject or PostMetadata are not subclasses of SyncObject and don't carry the isBookmarked attribute. They require there own delete operation
            if [Thumbnail.entityName(), MediaObject.entityName(), PostMetadata.entityName()].contains(entityName) {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                if self.onlyClearExpiredContent {
                    request.predicate = NSPredicate(format: "expirationDate != nil && expirationDate < %@", self.expirationDate(for: entityName))
                }
                return request
            } else {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                if self.onlyClearExpiredContent {
                    request.predicate = NSPredicate(format: "expirationDate != nil && expirationDate < %@ && isBookmarked != YES", self.expirationDate(for: entityName))
                    
                    if entityName == Subreddit.entityName() {
                        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [request.predicate!, NSPredicate(format: "lastVisitDate == nil")])
                    }
                } else {
                    request.predicate = NSPredicate(format: "isBookmarked != YES")
                }
                return request
            }
        })
    }

}
