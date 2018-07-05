//
//  Subreddit+Operations.swift
//  Snoo
//
//  Created by Robin Speijer on 17-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

public let MultiredditDidUpdateNotificationName = Notification.Name(rawValue: "MultiredditDidUpdateNotification")

extension Multireddit {
    
    public func createOperation(_ authenticationController: AuthenticationController) -> RedditMultiRequest {
        return multiRequestActionOperation(RedditMultiRequestAction.create, authenticationController: authenticationController)
    }
    
    public func updateOperation(_ authenticationController: AuthenticationController) -> RedditMultiRequest {
        return multiRequestActionOperation(RedditMultiRequestAction.update, authenticationController: authenticationController)
    }
    
    //Call this method on a new multireddit
    public func copyOperation(_ fromPermalink: String, authenticationController: AuthenticationController) -> RedditMultiRequest {
        let request = multiRequestActionOperation(RedditMultiRequestAction.copy, authenticationController: authenticationController)
        request.copyFromPermalink = fromPermalink
        return request
    }
    
    public func deleteOperation(_ authenticationController: AuthenticationController) -> RedditMultiRequest {
        return multiRequestActionOperation(RedditMultiRequestAction.delete, authenticationController: authenticationController)
    }
    
    public func renameOperation(_ authenticationController: AuthenticationController) -> RedditMultiRequest {
        return multiRequestActionOperation(RedditMultiRequestAction.rename, authenticationController: authenticationController)
    }
    
    fileprivate func multiRequestActionOperation(_ action: RedditMultiRequestAction, authenticationController: AuthenticationController) -> RedditMultiRequest {
        
        let request = RedditMultiRequest(multireddit: self, authenticationController: authenticationController)
        request.urlSession = authenticationController.userURLSession
        request.action = action
        request.requestCompletionHandler = { (error) -> Void in
            if action == RedditMultiRequestAction.delete {
                self.managedObjectContext?.delete(self)
            } else {
                if let data = request.result?["data"] as? NSDictionary {
                    if action == RedditMultiRequestAction.rename {
                        let usableData = NSMutableDictionary()
                        //We are only interested in the path, name and display_name in this response
                        if let value = data["path"] as? String {
                            usableData.setObject(value, forKey: "path" as NSCopying)
                        }
                        if let value = data["name"] as? String {
                            usableData.setObject(value, forKey: "name" as NSCopying)
                        }
                        if let value = data["display_name"] as? String {
                            usableData.setObject(value, forKey: "display_name" as NSCopying)
                        }
                        
                        do {
                            try self.parseObject(usableData, cache: nil)
                        } catch {
                            //If this parsing fails we should crash the app, otherwise we are dealing with a corrupt multireddit
                            fatalError("Failed parsing multireddit after multireddit name.")
                        }
                    } else {
                        do {
                            try self.parseObject(data, cache: nil)
                        } catch {
                            //We don't need to catch the error, if an error occurs the UI will just update after the new list of multireddits has been fetched.
                        }
                    }
                }
                
            }
            
            // The collection also changes on deletion or creation, so need to expire.
            if let collections = self.collections as? Set<ObjectCollection>, action == RedditMultiRequestAction.delete || action == RedditMultiRequestAction.create {
                for collection in collections {
                    collection.expirationDate = nil
                }
            }
        }
        
        request.completionBlock = { () -> Void in
            NotificationCenter.default.post(name: MultiredditDidUpdateNotificationName, object: self)
        }
        return request
        
    }
    
}
