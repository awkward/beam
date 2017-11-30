//
//  RedditRequest.swift
//  Snoo
//
//  Created by Robin Speijer on 17-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

open class RedditRequest: DataRequest {
    
    open let authenticationController: AuthenticationController
    
    override open var error: Error? {
        didSet {
            // If the user was unauthorized, try to refresh with the next request.
            if let error = error as NSError?, error.code == 401 {
                self.authenticationController.activeSession?.expirationDate = Date()
            }
        }
    }
    
    public init(authenticationController: AuthenticationController) {
        self.authenticationController = authenticationController
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(RedditRequest.applicationTokenChanged(_:)), name: AuthenticationController.ApplicationTokenDidChangeNotificationName, object: authenticationController)
        NotificationCenter.default.addObserver(self, selector: #selector(RedditRequest.userTokenChanged(_:)), name: AuthenticationController.UserTokenDidChangeNotificationName, object: authenticationController)
        
        self.urlSession = self.authenticationController.userURLSession
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc fileprivate func applicationTokenChanged(_ notification: Notification) {
        self.urlSession = self.authenticationController.userURLSession
    }
    
    @objc fileprivate func userTokenChanged(_ notification: Notification) {
        self.urlSession = self.authenticationController.userURLSession
    }
    
    var urlHostString: String {
        if authenticationController.isApplicationAuthenticated {
            return authenticationController.configuration.oauthHost
        } else {
            return authenticationController.configuration.regularHost
        }
    }
    
    var baseURL: URL {
        return URL(string: "https://\(self.urlHostString)")!
    }
    
    var oauthBaseURL: URL {
        return URL(string: "https://\(authenticationController.configuration.oauthHost)")!
    }
    
    var regularBaseURL: URL {
        return URL(string: "https://\(authenticationController.configuration.regularHost)")!
    }

}
