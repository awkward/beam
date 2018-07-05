//
//  RedditMultiRequest.swift
//  Snoo
//
//  Created by Robin Speijer on 13-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

public enum RedditMultiRequestAction {
    case update
    case create
    case delete
    case rename
    case copy
    
    func HTTPMethod() -> String {
        switch self {
        case .update:
            return "PUT"
        case .create:
            return "POST"
        case .delete:
            return "DELETE"
        case .rename:
            return "POST"
        case .copy:
            return "POST"
        }
    }
}

open class RedditMultiRequest: RedditRequest {
    
    open var multireddit: Multireddit
    open var action: RedditMultiRequestAction = .update
    open var copyFromPermalink: String?
    
    public init(multireddit: Multireddit, authenticationController: AuthenticationController) {
        self.multireddit = multireddit
        super.init(authenticationController: authenticationController)
    }
    
    override open var urlRequest: URLRequest? {
        get {
            if self.action == RedditMultiRequestAction.rename {
                if let url = URL(string: "api/multi/rename", relativeTo: self.oauthBaseURL as URL) {
                    let request = NSMutableURLRequest(url: url)
                    var body = [String: String]()
                    
                    body["display_name"] = self.multireddit.displayName
                    body["from"] = self.multireddit.permalink
                        
                    let escapedBody = self.stringFromQueryParameters(body)
                    let bodyData = escapedBody.replacingOccurrences(of: "%20", with: "+").data(using: String.Encoding.utf8, allowLossyConversion: true)
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    request.httpBody = bodyData
                    request.httpMethod = self.action.HTTPMethod()
                    
                    return request as URLRequest
                }
            } else if self.action == RedditMultiRequestAction.copy {
                if let url = URL(string: "api/multi/copy", relativeTo: self.oauthBaseURL as URL), let copyFromPermalink = self.copyFromPermalink {
                    let request = NSMutableURLRequest(url: url)
                    var body = [String: String]()
                    
                    self.multireddit.managedObjectContext?.performAndWait({ () -> Void in
                            body["display_name"] = self.multireddit.displayName
                            body["to"] = self.multireddit.permalink
                            body["from"] = copyFromPermalink
                    })
                    
                    let escapedBody = self.stringFromQueryParameters(body)
                    let bodyData = escapedBody.replacingOccurrences(of: "%20", with: "+").data(using: String.Encoding.utf8, allowLossyConversion: true)
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    request.httpBody = bodyData
                    request.httpMethod = self.action.HTTPMethod()
                    
                    return request as URLRequest
                }
            } else {
                if let permalink = multireddit.permalink, let url = URL(string: "api/multi/\(permalink)", relativeTo: self.oauthBaseURL as URL) {
                    let request = NSMutableURLRequest(url: url)
                    var body = [String: String]()
                    var thrownError: Error?
                    
                    if self.action != .delete {
                        multireddit.managedObjectContext?.performAndWait({ () -> Void in
                            do {
                                if let model = try self.multireddit.jsonRepresentation() {
                                    body["model"] = model
                                }
                                body["expand_srs"] = "true"
    //                            body["multipath"] = permalink
                            } catch {
                                thrownError = error as NSError
                            }
                        })
                    }
                    
                    if let error = thrownError {
                        NSLog("Could not create multireddit request: \(error)")
                        return nil
                    } else {
                        
                        let escapedBody = self.stringFromQueryParameters(body)
                        let bodyData = escapedBody.replacingOccurrences(of: "%20", with: "+").data(using: String.Encoding.utf8, allowLossyConversion: true)
                        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        request.httpBody = bodyData
                        request.httpMethod = self.action.HTTPMethod()
                        
                        return request as URLRequest
                    }
                }
            }
            return nil
        }
        set {
            
        }
    }

}
