//
//  RedditRequest.swift
//  Snoo
//
//  Created by Robin Speijer on 11-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import UIKit

public typealias RedditRequestHandler = (([String: AnyObject]?, Error?) -> Void)

open class DataRequest: SnooOperation {
    
    internal var privateUrlSession: URLSession?
    
    open var urlSession: URLSession {
        get {
            if self.privateUrlSession == nil {
                self.privateUrlSession = URLSession(configuration: URLSessionConfiguration.default)
            }
            return self.privateUrlSession!
        }
        set {
            self.privateUrlSession = newValue
        }
    }
    
    open var urlRequest: URLRequest?
    
    /// The response returned from the NSURLRequest. Can be used to check status codes
    open var HTTPResponse: HTTPURLResponse?
    
    /// A completion handler to be completed in the operation thread. The operation will wait for the completion handler before changing to the finished state.
    open var requestCompletionHandler: ((Error?) -> Void)?
    
    open var result: NSDictionary? {
        didSet {
            self.requestCompletionHandler?(nil)
        }
    }
    
    override open var error: Error? {
        didSet {
            self.requestCompletionHandler?(self.error)
        }
    }
    
    fileprivate var dataTask: URLSessionDataTask?
    
    public override init() {
        super.init()
    }
    
    deinit {
        self.dataTask?.cancel()
    }
    
    open override func start() {
        super.start()
        
        if let urlRequest: URLRequest = self.urlRequest {
            guard self.isCancelled == false else {
                self.finishOperation()
                return
            }
            
            let startDate: Date = Date()
            self.dataTask = self.urlSession.dataTask(with: urlRequest, completionHandler: { (data, urlResponse, responseError) in
                guard self.isCancelled == false else {
                    self.finishOperation()
                    return
                }
                self.HTTPResponse = urlResponse as? HTTPURLResponse
                
                /*
                Reddit often responds with a 200 status code, however in some cases a 201 might be sent upon creation.
                However some requests on reddit come with a 202 status code (for example, mark all messages as read), this means the request is still fullfilled, but the body will not be json (even if the header says so).
                These requests almost never have any useful body anyway.
                */
                
                if let httpResponse: HTTPURLResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode >= 300 {
                    self.error = NSError.snooError(httpResponse.statusCode, localizedDescription: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                } else if let httpResponse: HTTPURLResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 && (data?.count == 0 || httpResponse.statusCode == 202) {
                    self.result = [String: AnyObject]() as NSDictionary?
                } else if let data: Data = data {
                    do {
                        let responseData: NSDictionary? = try self.responseData(data)
                        if let responseErrors = (responseData?["json"] as? NSDictionary)?["errors"] as? NSArray {
                            guard responseErrors.count == 0 else {
                                self.error = NSError.redditError(errorsArray: responseErrors)
                                self.finishOperation()
                                return
                            }
                            if let json: NSDictionary = responseData?["json"] as? NSDictionary, json.count == 1 {
                                guard let httpResponse: HTTPURLResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                                    self.error = NSError.redditError(errorsArray: responseErrors)
                                    self.finishOperation()
                                    return
                                }
                                self.result = responseData
                            } else {
                                self.result = responseData
                            }
                        } else {
                            self.result = responseData
                        }
                    } catch {
                        if let jsonBody: NSString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                            NSLog("Invalid reddit reponse body: %@", jsonBody)
                        } else {
                            NSLog("Empty request response body.")
                        }
                        self.error = error
                    }
                } else if UIApplication.shared.applicationState != UIApplicationState.active || (startDate as NSDate).laterDate(Date(timeIntervalSinceNow: -1 * urlRequest.timeoutInterval)) != startDate {
                    self.cancelOperation()
                } else if let responseError: NSError = responseError as NSError? {
                    self.error = responseError
                } else {
                    self.error = NSError.snooError(500, localizedDescription: "Empty reddit response")
                }
                self.finishOperation()
            })
            self.dataTask?.resume()
        } else {
            self.error = NSError.snooError(400, localizedDescription: "No URL request for reddit request")
            self.finishOperation()
        }
        
    }
    
    open override func cancel() {
        super.cancelOperation()
        self.dataTask?.cancel()
        self.dataTask = nil
    }
    
    fileprivate func responseData(_ data: Data) throws -> NSDictionary? {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        if let result = object as? NSDictionary {
            return result
        } else if let result = object as? NSArray {
            return ["data": ["children": result]]
        } else {
            return nil
        }
    }
    
    func stringFromQueryParameters(_ queryParameters: [String: String]) -> String {
        var parts: [String] = []
        for (name, value) in queryParameters {
            let part = NSString(format: "%@=%@",
                URL.stringByAddingUrlPercentagesToString(name)!,
                URL.stringByAddingUrlPercentagesToString(value)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
    
    open class func formPOSTDataWithParameters(_ parameters: [String: String]) -> Data? {
        var strings = [String]()
        for (key, value) in parameters {
            let encodedKey = self.formEncodedString(key)
            let encodedValue = self.formEncodedString(value)
            strings.append("\(encodedKey)=\(encodedValue)")
        }
        return strings.joined(separator: "&").data(using: String.Encoding.utf8)
    }
    
    fileprivate class func formEncodedString(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        let allowedCharacterSet = (NSMutableCharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharacters(in: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        if let escapedString: String = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet) {
            return escapedString
        }
        return string
    }
    
}
