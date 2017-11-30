//
//  ApplicationTokenRequest.swift
//  Snoo
//
//  Created by Robin Speijer on 01-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

/// The OAuth2 grant type to be used for retreiving an authentication session.
enum AccessTokenGrant {
    
    /// An application specific grant type, linked to a device identifier.
    case installedClient(String)
    
    /// The first login grant type. Requires a code returned by the OAuth2 web flow.
    case authorizationCode(String)
    
    /// The refresh grant type. Requires a refresh token.
    case refreshToken(String)
    
}

class AccessTokenRequest: DataRequest {
    
    var grant: AccessTokenGrant
    var clientId: String
    var authenticationController: AuthenticationController
    
    override var result: NSDictionary? {
        willSet {
            if let result = newValue {
                self.authenticationSession = AuthenticationSession(dictionary: result)
            } else {
                self.authenticationSession = nil
            }
        }
    }
    
    var authenticationSession: AuthenticationSession?
    
    init(grant: AccessTokenGrant, clientId: String, authenticationController: AuthenticationController) {
        self.grant = grant
        self.clientId = clientId
        self.authenticationController = authenticationController
        super.init()
        self.urlSession = authenticationController.userURLSession
    }
    
    override var urlRequest: URLRequest? {
        get {
            if let url = URL(string: "https://www.reddit.com/api/v1/access_token") {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue(self.authorizationValue, forHTTPHeaderField: "Authorization")
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.httpBody = self.requestBody
                return request
            } else {
                fatalError()
            }
        } set {
            
        }
    }
    
    fileprivate var authorizationValue: String {
        let loginString = "\(self.clientId):"
        let loginData = loginString.data(using: String.Encoding.utf8)
        if let loginBase64 = loginData?.base64EncodedString(options: []) {
            return "Basic \(loginBase64)"
        } else {
            return "Basic"
        }
    }
    
    fileprivate var requestBody: Data? {
        let bodyParameters = self.postValues()
        var urlComponents = URLComponents()
        urlComponents.queryItems = bodyParameters.map({ (key, value) -> URLQueryItem in
            return URLQueryItem(name: key, value: "\(value)")
        })
        let bodyString = urlComponents.percentEncodedQuery
        return bodyString?.data(using: String.Encoding.utf8)
    }
    
    fileprivate func postValues() -> [String: Any] {
        var parameters = [String: Any]()
        switch self.grant {
        case .authorizationCode(let code):
            parameters["grant_type"] = "authorization_code"
            parameters["code"] = code
            parameters["redirect_uri"] = self.authenticationController.configuration.redirectUri
        case .installedClient(let deviceId):
            parameters["grant_type"] = "https://oauth.reddit.com/grants/installed_client"
            parameters["device_id"] = deviceId
        case .refreshToken(let refreshToken):
            parameters["grant_type"] = "refresh_token"
            parameters["refresh_token"] = refreshToken
        }
        return parameters
    }
    
}
