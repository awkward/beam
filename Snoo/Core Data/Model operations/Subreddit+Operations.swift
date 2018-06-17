//
//  Subreddit+Operations.swift
//  Snoo
//
//  Created by Robin Speijer on 21-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

extension NSNotification.Name {
    public static let SubredditSubscriptionDidChange = NSNotification.Name(rawValue: "SubscriptionDidChangeNotification")
    public static let PostSubmitted = NSNotification.Name(rawValue: "PostSubmittedNotification")
    public static let SubredditBookmarkDidChange = NSNotification.Name(rawValue: "SubredditBookmarkDidChange")
}

extension Subreddit {

    public func subscribeOperations(_ authenticationController: AuthenticationController, unsubscribe: Bool = false) -> [Operation] {
        
        let request = RedditSubscriptionRequest(subreddit: self, authenticationController: authenticationController)
        request.action = unsubscribe ? .Unsubscribe : .Subscribe
        request.completionBlock = { () -> Void in
            
        }
        
        let parsing = BlockOperation { () -> Void in
            if request.error == nil {
                self.managedObjectContext?.perform({ () -> Void in
                    self.isSubscriber = NSNumber(value: !unsubscribe as Bool)
                    
                    if unsubscribe {
                        if let subredditCollections = self.collections?.filter({ $0 is SubredditCollection }) as? [SubredditCollection] {
                            for collection in subredditCollections {
                                if var objects = collection.objects?.array as? [Subreddit], let index = objects.index(of: self) {
                                    objects.remove(at: index)
                                    collection.objects = NSOrderedSet(array: objects)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: .SubredditSubscriptionDidChange, object: self)
                    })
                })
            }
        }
        parsing.addDependency(request)
        
        return [request, parsing]
    }

    public class func clearAllVisitedDatesOperation(_ context: NSManagedObjectContext) -> Operation {
        
        return BlockOperation { () -> Void in
            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 9 {
                let request = NSBatchUpdateRequest(entityName: self.entityName())
                request.predicate = NSPredicate(format: "lastVisitDate != nil")
                request.propertiesToUpdate = ["lastVisitDate": NSExpression(forConstantValue: nil)]
                request.resultType = NSBatchUpdateRequestResultType.statusOnlyResultType
                context.performAndWait({ () -> Void in
                    do {
                        try context.execute(request)
                    } catch {
                        NSLog("Error while clearing out last visited dates: \(error)")
                    }
                })
            } else {
                let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName())
                request.predicate = NSPredicate(format: "lastVisitDate != nil")
                context.performAndWait({ () -> Void in
                    do {
                        if let subreddits = try context.fetch(request) as? [Subreddit] {
                            for subreddit in subreddits {
                                subreddit.lastVisitDate = nil
                            }
                        }
                    } catch {
                        NSLog("Error while clearing out last visited dates: \(error)")
                    }
                })
            }
           
        }
        
    }
    
    public func submitRequestAndOperations(_ title: String, kind: RedditSubmitKind, context: NSManagedObjectContext, authenticationController: AuthenticationController) throws -> (request: RedditSubmitRequest, operations: [Operation]) {
        guard self.displayName != nil else {
            throw NSError.snooError(404, localizedDescription: "Subreddit name missing")
        }
        let request = RedditSubmitRequest(title: title, kind: kind, subredditName: self.displayName!, authenticationController: authenticationController)
        request.requestCompletionHandler = { (error) in
            if error == nil {
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: .PostSubmitted, object: self)
                })
                
            }
        }
        return (request: request, operations: [request])
    }
    
}
