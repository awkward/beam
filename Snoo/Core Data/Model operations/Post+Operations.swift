//
//  Post+Operations.swift
//  Snoo
//
//  Created by Rens Verhoeven on 23-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

public enum PostReportReason: String {
    case Spam = "spam"
    case VoteManipulation = "vote manipulation"
    case PersonalInformation = "personal information"
    case SexualizingMinors = "sexualizing minors"
    case BreakingReddit = "breaking reddit"
    case Other = "other"
}

extension Notification.Name {
    
    public static let PostDidChangeHiddenState = Notification.Name(rawValue: "PostDidChangeHiddenStateNotification")
    
}

extension Post {
    
    public func markHiddenOperation(_ hidden: Bool, authenticationController: AuthenticationController) -> Operation {
        if authenticationController.isAuthenticated {
            let request = RedditRequest(authenticationController: authenticationController)
            request.urlSession = authenticationController.userURLSession
            let command = hidden ? "hide" : "unhide"
            let url = URL(string: "/api/\(command)", relativeTo: request.baseURL as URL)!
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "id", value: self.objectName)]
            
            var urlRequest = URLRequest(url: urlComponents.url!)
            urlRequest.httpMethod = "POST"
            request.urlRequest = urlRequest
            
            request.completionBlock = { [weak self] () in
                self?.managedObjectContext?.perform({ () -> Void in
                    self?.isHidden = NSNumber(value: hidden as Bool)
                })
            }
            
            return request
        } else {
            return BlockOperation(block: { () -> Void in
                self.isHidden = true
            })
        }

    }
    
}
