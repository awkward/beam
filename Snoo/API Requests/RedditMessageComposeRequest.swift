//
//  RedditMessageComposeRequest.swift
//  Beam
//
//  Created by Rens Verhoeven on 14/12/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

open class RedditMessageComposeRequest: RedditRequest {
    
    var user: User
    var subject: String
    var message: String
    
    public init(user: User, subject: String, message: String, authenticationController: AuthenticationController) {
        self.user = user
        self.subject = subject
        self.message = message
        super.init(authenticationController: authenticationController)
    }
    
    override open var urlRequest: URLRequest? {
        get {
            guard let url = URL(string: "/api/compose", relativeTo: self.oauthBaseURL as URL),
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                    return nil
            }
            urlComponents.queryItems = [URLQueryItem(name: "api_type", value: "json")]
            if let requestURL = urlComponents.url {
                let request = NSMutableURLRequest(url: requestURL)
                request.httpBody = DataRequest.formPOSTDataWithParameters(self.POSTBodyParameters)
                request.httpMethod = "POST"
                
                return request as URLRequest
            }
            return nil
        }
        set {
            // Not a stored property anymore
        }
        
    }
    
    fileprivate var POSTBodyParameters: [String: String] {
        guard let username = self.user.username else {
            //If username misses, the request will throw an error anyway. So we just return an empty dictionary.
            return [:]
        }
        return ["subject": self.subject, "text": self.message, "to": username, "api_type": "json"]
    }
    
}
