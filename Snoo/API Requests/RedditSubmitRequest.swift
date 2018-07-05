//
//  RedditSubmitRequest.swift
//  Snoo
//
//  Created by Rens Verhoeven on 22-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

public enum RedditSubmitKind {
    case link(URL)
    case text(String?)
}

open class RedditSubmitRequest: RedditRequest {
    
    var submitKind: RedditSubmitKind
    var title: String
    var subredditName: String
    
    open var resubmit = false
    open var sendReplies = true
    
    public init(title: String, kind: RedditSubmitKind, subredditName: String, authenticationController: AuthenticationController) {
        self.title = title
        self.submitKind = kind
        self.subredditName = subredditName
        super.init(authenticationController: authenticationController)
    }
    
    override open var urlRequest: URLRequest? {
        get {
            let url = Foundation.URL(string: "/api/submit", relativeTo: self.oauthBaseURL as URL)
            var urlComponents = URLComponents(url: url!, resolvingAgainstBaseURL: true)
            urlComponents?.queryItems = [URLQueryItem(name: "api_type", value: "json")]
            if let requestURL = urlComponents?.url {
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
        var kind: String!
        var kindSpecificParameters: [String: String]!
        switch self.submitKind {
        case RedditSubmitKind.link(let url):
            let urlString: String = url.absoluteString
            kindSpecificParameters = ["url": urlString]
            kind = "link"
        case RedditSubmitKind.text(let selfText):
            if let text: String = selfText {
                kindSpecificParameters = ["text": text]
            } else {
                kindSpecificParameters = [String: String]()
            }
            kind = "self"
        }
        var parameters: [String: String] = ["title": self.title, "sr": self.subredditName, "kind": kind, "api_type": "json", "resubmit": self.resubmit ? "true" : "false", "sendreplies": self.sendReplies ? "true" : "false"]
        for (key, value) in kindSpecificParameters {
            parameters[key] = value
        }
        return parameters
    }

}
