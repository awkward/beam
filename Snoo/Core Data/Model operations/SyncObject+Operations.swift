//
//  SyncObject+Operations.swift
//  Snoo
//
//  Created by Rens Verhoeven on 04-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

extension SyncObject {
    
    public func reportOperation(_ reason: PostReportReason, otherReason: String?, authenticationController: AuthenticationController) -> Operation {
        if !authenticationController.isAuthenticated {
            let operation = BlockOperation(block: { () -> Void in
                self.markAsReported()
            })
            return operation
        } else {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession
            let url = URL(string: "/api/report", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            
            var queryItems = [URLQueryItem(name: "api_type", value: "json"), URLQueryItem(name: "thing_id", value: self.objectName), URLQueryItem(name: "reason", value: reason.rawValue)]
            if let otherReason = otherReason {
                queryItems.append(URLQueryItem(name: "other_reason", value: otherReason))
            }
            urlComponents.queryItems = queryItems
            
            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest
            
            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.markAsReported()
                })
            }
            
            return request
        }
        
    }
    
    /**
     Mark the post as reported, set the hasBeenReported property and in case of an actual post change the hidden flag
     */
    func markAsReported() {
        if let post = self as? Post {
            post.isHidden = true
        }
        self.hasBeenReported = true
        self.expirationDate = nil
    }
    
}
