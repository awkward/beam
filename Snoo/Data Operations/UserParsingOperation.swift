//
//  UserParsingOperation.swift
//  Snoo
//
//  Created by Robin Speijer on 09-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

/// An operation that parses the result from a RedditMeRequest into the given object context. By default, this is the private context. You MUST make this operation dependent on the RedditUserRequest operation.
final public class UserParsingOperation: DataOperation {
    
    // Input
    public var objectContext: NSManagedObjectContext! = DataController.shared.privateContext
    
    open var userParsingCompletionHandler: (() -> Void)?
    
    // Output
    open var userID: NSManagedObjectID?
    open var userIdentifier: String?
    open var username: String?

    override open func start() {
        super.start()
        
        let userRequest = self.dependencies.first(where: { (operation) -> Bool in
            return operation is RedditUserRequest
        })
        if let userRequest = userRequest as? RedditUserRequest, let data = userRequest.result {

            self.objectContext?.performAndWait { () -> Void in
                guard self.isCancelled == false else {
                    return
                }
                var userData = data
                if data["data"] != nil {
                    userData = data["data"] as! NSDictionary
                }
                
                let identifier = userData["id"] as? String
                if let identifier = identifier {
                    
                    do {
                        if let parsedUser = try User.objectWithIdentifier(identifier, cache: nil, context: self.objectContext) as? User {
                            try parsedUser.parseObject(userData, cache: nil)
                            self.userIdentifier = parsedUser.identifier
                            self.username = parsedUser.username
                            
                            if parsedUser.objectID.isTemporaryID {
                                try self.objectContext.obtainPermanentIDs(for: [parsedUser])
                            }
                            
                            self.userID = parsedUser.objectID
                        }
                    } catch {
                        self.error = error as NSError
                    }
                    
                }
            }
            
        }
        
        if self.userID == nil && self.error == nil {
            self.error = NSError(domain: "Snoo", code: 400, userInfo: [NSLocalizedDescriptionKey: "Parsing error for the user object"])
        }
        
        self.userParsingCompletionHandler?()
        
        self.finishOperation()
    }
    
}
