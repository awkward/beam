//
//  RedditSubscriptionRequest.swift
//  Snoo
//
//  Created by Robin Speijer on 03-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

public enum RedditSubscriptionRequestAction: String {
    case Subscribe = "sub"
    case Unsubscribe = "unsub"
}

open class RedditSubscriptionRequest: RedditRequest {
    
    open let subreddit: Subreddit
    open var action = RedditSubscriptionRequestAction.Subscribe
    
    public init(subreddit: Subreddit, authenticationController: AuthenticationController) {
        self.subreddit = subreddit
        super.init(authenticationController: authenticationController)
    }
    
    override open var urlRequest: URLRequest? {
        get {
            if let url = URL(string: "api/subscribe", relativeTo: self.oauthBaseURL as URL) {
                let request = NSMutableURLRequest(url: url)
                request.httpMethod = "POST"
                self.subreddit.managedObjectContext?.performAndWait({ () -> Void in
                    request.httpBody = "action=\(self.action.rawValue)&sr=\(self.subreddit.objectName!)".data(using: String.Encoding.utf8)
                })
                return request as URLRequest
            }
            return nil
        }
        set {
            // Not a stored property anymore
        }
    }

}
