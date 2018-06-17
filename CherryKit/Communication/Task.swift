//
//  CherryRequest.swift
//  CherryKit
//
//  Created by Robin Speijer on 16-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum RequestMethod: String {
    case Get = "GET"
    case Post = "POST"
    case Put = "PUT"
    case Delete = "DELETE"
}

open class TaskResult: NSObject {
    open let error: Error?
    open var response: HTTPURLResponse?
    
    init(error: Error?) {
        self.error = error
        super.init()
    }
    
    init(error: Error?, response: HTTPURLResponse?) {
        self.error = error
        self.response = response
        super.init()
    }
}

public typealias RequestCompletionHandler = ((TaskResult) -> Void)

open class Task: NSObject {

    fileprivate var baseURL: String {
        #if DEBUG
            return "http://staging-api.beamreddit.com"
        #else
            return "http://api.beamreddit.com"
        #endif
    }
    
    fileprivate var baseShareURL: String {
        #if DEBUG
            return "http://staging-share.beamreddit.com"
        #else
            return "http://share.beamreddit.com"
        #endif
    }
    
    var accessToken: String
    var apiPath: String {
        return ""
    }
    var apiVersion = "v1"
    
    fileprivate var dataTask: URLSessionDataTask?
    
    public init(token: String) {
        self.accessToken = token
        super.init()
    }
    
    func cherryRequest(_ apiPath: String, queryItems: [URLQueryItem]? = nil, method: RequestMethod) -> URLRequest {
        var baseURL = self.baseURL
        #if !DEBUG
            if apiPath.lowercased() == "hello" {
                baseURL = "http://hello.beamreddit.com"
            }
        #endif
        
        var components = URLComponents(string: baseURL)
        components?.path = "/\(self.apiVersion)/\(apiPath)"
        
        if let queryItems = queryItems {
            components?.queryItems = queryItems
        }
        if let url = components?.url {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            if method == .Post || method == .Put {
                request.httpBody = ("{}" as NSString).data(using: String.Encoding.utf8.rawValue)
            }
            request.setValue("token \(self.accessToken)", forHTTPHeaderField: "Authorization")
            return request
        } else {
            fatalError("Can not build a URL'")
        }
    }
    
    func cherryShareRequest(_ apiPath: String, queryItems: [URLQueryItem]? = nil, method: RequestMethod) -> URLRequest {
        var components = URLComponents(string: self.baseURL)
        components?.path = "/\(self.apiVersion)/\(apiPath)"
        
        if let queryItems = queryItems {
            components?.queryItems = queryItems
        }
        if let url = components?.url {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            if method == .Post || method == .Put {
                request.httpBody = ("{}" as NSString).data(using: String.Encoding.utf8.rawValue)
            }
            request.setValue("token \(self.accessToken)", forHTTPHeaderField: "Authorization")
            return request
        } else {
            fatalError("Can not build a Share URL")
        }
    }
    
    var request: URLRequest {
        return cherryRequest(self.apiPath, method: .Post)
    }
    
    open func start(_ completionHandler: RequestCompletionHandler?) {
        var request = self.request
        if let signature = Cherry.signatureForRequest?(request) {
            request.setValue(signature, forHTTPHeaderField: "X-Signature")
        }
        
        self.dataTask = Cherry.urlSession.dataTask(with: request, completionHandler: { (data, response, error) in
            
            if let error = error {
                completionHandler?(TaskResult(error: error, response: (response as? HTTPURLResponse)))
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                do {
                    if let data = data, let errorObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject], let message = errorObject["message"] as? String {
                        let error = NSError(domain: CherryKitErrorDomain, code: CherryKitNetworkingErrorCode, userInfo: [NSLocalizedDescriptionKey: message])
                        completionHandler?(TaskResult(error: error, response: (response as? HTTPURLResponse)))
                        return
                    }
                } catch {
                    NSLog("Could not parse cherry error message JSON")
                }
                let error = NSError(domain: CherryKitErrorDomain, code: CherryKitNetworkingErrorCode, userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)])
                completionHandler?(TaskResult(error: error, response: (response as? HTTPURLResponse)))
            } else if let data = data {
                let result = self.parseJSONData(data)
                if let completionHandler = completionHandler {
                    completionHandler(result)
                }
                
            } else {
                let error = NSError(domain: CherryKitErrorDomain, code: CherryKitNetworkingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Failed to complete Cherry request"])
                completionHandler?(TaskResult(error: error, response: (response as? HTTPURLResponse)))
            }
        })
        
        if let task = self.dataTask {
            task.resume()
        } else {
            let error = NSError(domain: CherryKitErrorDomain, code: CherryKitNetworkingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Could not setup NSURLSession data task"])
            completionHandler?(TaskResult(error: error))
        }
    }
    
    open func cancel() {
        dataTask?.cancel()
    }
    
    func parseJSONData(_ data: Data) -> TaskResult {
        fatalError("Generic request does not know how to parse")
    }
    
}
