//
//  ContentOperations.swift
//  Snoo
//
//  Created by Robin Speijer on 17-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

extension Notification.Name {
    public static let ContentDidChangeSavedState = Notification.Name(rawValue: "ContentDidChangeSavedState")
    public static let ContentDidDelete = Notification.Name(rawValue: "ContentDidDeleteNotification")
}

extension Content {

    public func voteOperation(_ direction: VoteStatus, authenticationController: AuthenticationController) -> Operation {
        let request = RedditRequest(authenticationController: authenticationController)
        request.urlSession = authenticationController.userURLSession
        var urlRequest = URLRequest(url: URL(string: "/api/vote?dir=\(direction.rawValue)&id=\(self.objectName!)", relativeTo: request.baseURL as URL)!)
        urlRequest.httpMethod = "POST"
        request.urlRequest = urlRequest
        return request
    }
    
    public func replyOperations(_ content: String, authenticationcontroller: AuthenticationController) -> [Operation] {
        let redditRequest = RedditRequest(authenticationController: authenticationcontroller)
        redditRequest.urlSession = authenticationcontroller.userURLSession
        let commentURL = URL(string: "/api/comment", relativeTo: redditRequest.baseURL as URL)!
        var commentURLComponents = URLComponents(url: commentURL, resolvingAgainstBaseURL: true)
        commentURLComponents?.queryItems = [URLQueryItem(name: "api_type", value: "json")]
        
        if let url = commentURLComponents?.url {
            var urlRequest = URLRequest(url: url)
            let parameters = ["api_type": "json", "thing_id": self.objectName!, "text": content]
            urlRequest.httpBody = DataRequest.formPOSTDataWithParameters(parameters)
            urlRequest.httpMethod = "POST"
            redditRequest.urlRequest = urlRequest
        }
        
        if let context = self.managedObjectContext {
            let parsingOperation = ThingsParsingOperation(request: redditRequest, context: context)
            parsingOperation.addDependency(redditRequest)
            return [redditRequest, parsingOperation]
        } else {
            return [redditRequest]
        }
    }
    
    public func deleteOperations(_ authenticationcontroller: AuthenticationController) -> [Operation] {
        let redditRequest = RedditRequest(authenticationController: authenticationcontroller)
        redditRequest.urlSession = authenticationcontroller.userURLSession
        let commentURL = URL(string: "/api/del", relativeTo: redditRequest.baseURL as URL)!
        var commentURLComponents = URLComponents(url: commentURL, resolvingAgainstBaseURL: true)
        //Because of a bug in the reddit api, for some POST endpoints "api_type" has to be appended to the URL, otherwise the response is incorrect
        commentURLComponents?.queryItems = [URLQueryItem(name: "api_type", value: "json")]
        
        if let url = commentURLComponents?.url {
            var request = URLRequest(url: url)
            let parameters = ["api_type": "json", "id": self.objectName!]
            request.httpBody = DataRequest.formPOSTDataWithParameters(parameters)
            request.httpMethod = "POST"
            redditRequest.urlRequest = request
        }
        
        return [redditRequest]
    }
    
    public func updateOperations(_ content: String, authenticationcontroller: AuthenticationController) throws -> [Operation] {
        guard self.objectName != nil else {
            throw NSError.snooError(404, localizedDescription: "Object name missing")
        }
        let redditRequest = RedditRequest(authenticationController: authenticationcontroller)
        redditRequest.urlSession = authenticationcontroller.userURLSession
        let commentURL = URL(string: "/api/editusertext", relativeTo: redditRequest.baseURL as URL)!
        var commentURLComponents = URLComponents(url: commentURL, resolvingAgainstBaseURL: true)
        //Because of a bug in the reddit api, for some POST endpoints "api_type" has to be appended to the URL, otherwise the response is incorrect
        commentURLComponents?.queryItems = [URLQueryItem(name: "api_type", value: "json")]
        
        if let url = commentURLComponents?.url {
            var request = URLRequest(url: url)
            let parameters = ["api_type": "json", "thing_id": self.objectName!, "text": content]
            request.httpBody = DataRequest.formPOSTDataWithParameters(parameters)
            request.httpMethod = "POST"
            redditRequest.urlRequest = request
        }
        
        if let context = self.managedObjectContext {
            let parsingOperation = ThingsParsingOperation(request: redditRequest, context: context)
            parsingOperation.addDependency(redditRequest)
            return [redditRequest, parsingOperation]
        } else {
            return [redditRequest]
        }
    }
    
    public func saveToRedditOperation(_ save: Bool, authenticationController: AuthenticationController) -> Operation {
        let request = RedditRequest(authenticationController: authenticationController)
        request.urlSession = authenticationController.userURLSession
        let command = save ? "save" : "unsave"
        let url = URL(string: "/api/\(command)", relativeTo: request.baseURL as URL)!
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "id", value: self.objectName)]
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "POST"
        request.urlRequest = urlRequest
        
        request.completionBlock = { [weak self] () in
            self?.managedObjectContext?.perform({ () -> Void in
                self?.isSaved = NSNumber(value: save as Bool)
            })
        }
        
        return request
    }
    
}
