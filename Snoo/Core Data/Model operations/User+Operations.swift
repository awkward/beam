//
//  User+Operations.swift
//  Beam
//
//  Created by Rens Verhoeven on 14/12/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

extension User {
    
    /// This function will return a tuple with the request and the operations to perform
    /// This calls the /api/compose endpoint on reddit.
    ///
    /// - Parameters:
    ///   - subject: The subject of the message
    ///   - message: The content of the message
    ///   - authenticationController: The authentication controller
    /// - Returns: A tuple with the API request and an array of operations to perform (including the request)
    /// - Throws: Throws an error if the user model is missing a username
    public func redditMessageComposeOperation(subject: String, message: String, authenticationController: AuthenticationController) throws -> (request: RedditMessageComposeRequest, operations: [Operation]) {
        guard self.username != nil else {
            throw NSError.snooError(404, localizedDescription: "Username missing")
        }
        
        let request = RedditMessageComposeRequest(user: self, subject: subject, message: message, authenticationController: authenticationController)
        request.requestCompletionHandler = { (error) in
            if error == nil {
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: .RedditMessageDidSend, object: self)
                })
            }
        }
        return (request: request, operations: [request])
    }
}
