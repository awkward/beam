//
//  RedditMeRequest.swift
//  Snoo
//
//  Created by Robin Speijer on 19-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum RedditMeRequestType: String {
    case overview = ""
    case karma = "karma"
    case prefs = "prefs"
    case trophies = "trophies"
}

open class RedditUserRequest: RedditRequest {
    
    var requestType = RedditMeRequestType.overview
    open var username: String?
    
    override open var urlRequest: URLRequest? {
        get {
            if let usernameString = self.username {
                var requestTypeString = requestType.rawValue
                if self.requestType == .overview {
                    requestTypeString = "about"
                }
                if let url = URL(string: "/user/\(usernameString)/\(requestTypeString)", relativeTo: self.oauthBaseURL as URL) {
                    return URLRequest(url: url)
                }
            } else {
                if let url = URL(string: "api/v1/me/\(requestType.rawValue)", relativeTo: self.oauthBaseURL as URL) {
                    return URLRequest(url: url)
                }
            }
            return nil
        }
        set {
            // Not a stored property anymore
        }
        
    }
    
    open override func start() {
        //Set the URL Session only if there is a token request before it. Else it will pick up the URL Session automatically from the AuthenticationController.
        if let accessTokenRequest = self.dependencies.first(where: { (operation) -> Bool in
            return operation is AccessTokenRequest
        }) as? AccessTokenRequest, let session = accessTokenRequest.authenticationSession {
            self.urlSession = self.urlSessionWithAuthenticationSession(session)
        }
        
        super.start()
    }
    
    func urlSessionWithAuthenticationSession(_ session: AuthenticationSession) -> URLSession {
        let configuration = self.authenticationController.basicURLSessionConfiguration
        var headers = configuration.httpAdditionalHeaders ?? [AnyHashable: Any]()
        if let tokenType = session.tokenType, let token = session.accessToken {
            headers["Authorization"] = "\(tokenType) \(token)"
        } else {
            NSLog("Could not add authorization to RedditUserRequest")
        }
        
        configuration.httpAdditionalHeaders = headers
        
        return URLSession(configuration: configuration)
    }
    
}
