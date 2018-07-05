//
//  ImgurRequest.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

public enum ImgurHTTPMethod: String {
    case Delete = "DELETE"
    case Create = "POST"
    case Update = "PUT"
    case Get = "GET"
}

public class ImgurRequest: Operation {
    
    // MARK: - Operation methods
    
    fileprivate var operationIsExecuting: Bool = false {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
        }
        didSet {
            self.didChangeValue(forKey: "isExecuting")
        }
    }
    
    fileprivate var operationIsCancelled: Bool = false {
        willSet {
            self.willChangeValue(forKey: "isCancelled")
        }
        didSet {
            self.didChangeValue(forKey: "isCancelled")
        }
    }
    
    fileprivate var operationIsFinished: Bool = false {
        willSet {
            self.willChangeValue(forKey: "isFinished")
        }
        didSet {
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    /**
     Start the NSOperation. This method will notify KVO that "isExecuting" has changed.
     */
    fileprivate func startOperation() {
        self.operationIsExecuting = true
    }
    
    /**
     Cancel the NSOperation. This method will notify KVO that "isCancelled" has changed.
     */
    fileprivate func cancelOperation() {
        self.operationIsCancelled = true
        self.currentTask?.cancel()
    }
    
    /**
     Finish the NSOperation. This method will notify KVO that "isFinished" has changed.
     */
    open func finishOperation() {
        self.operationIsFinished = true
    }
    
    override open func start() {
        self.startOperation()
        self.addParameters()
        
        if self.isCancelled {
            self.finishOperation()
            return
        }
        self.performRequest { (resultObject, error) in
            self.error = error
            self.resultObject = resultObject
            self.finishOperation()
        }
    }
    
    /**
     If needed, subclassed of DataOperation can override this method to received the cancel operation and cancel a request.
     */
    override open func cancel() {
        self.cancelOperation()
    }
    
    override open var isAsynchronous: Bool {
        return true
    }
    
    override open var isExecuting: Bool {
        return self.operationIsExecuting
    }
    
    override open var isFinished: Bool {
        return self.operationIsFinished
    }
    
    override open var isCancelled: Bool {
        return self.operationIsCancelled
    }
    
    // MARK: - Imgur controller
    
    internal var imgurController: ImgurController!
    
    // MARK: - Request methods and properties
    
    open var endpoint: String!
    open var parameters: [String: Any]?
    open var HTTPMethod: ImgurHTTPMethod = ImgurHTTPMethod.Get
    
    open var deleteHash: String?
    
    open var uploadProgressHandler: ((_ request: ImgurRequest, _ progress: CGFloat) -> Void)?
    open var downloadProgressHandler: ((_ request: ImgurRequest, _ progress: CGFloat) -> Void)?
    
    open var uploadProgress: CGFloat = 0
    open var downloadProgress: CGFloat = 0
    
    internal var currentTask: URLSessionTask?
    
    internal var uploadProgressObserver: NSKeyValueObservation?
    internal var downloadProgressObserver: NSKeyValueObservation?
    
    internal var URLRequest: Foundation.URLRequest {
        let URL = Foundation.URL(string: endpoint, relativeTo: self.imgurController.APIURL as URL)!
        let request = NSMutableURLRequest(url: URL)
        request.httpMethod = self.HTTPMethod.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            if let parameters = self.parameters {
                let data = try JSONSerialization.data(withJSONObject: parameters, options: [])
                request.httpBody = data
            }
        } catch let error as NSError {
            NSLog("Error creating body \(error)")
        }
        
        return request as URLRequest
    }
    
    internal var session: URLSession {
        return self.imgurController.URLSession
    }
    
    internal func addParameters() {
        
    }
    
    internal func performRequest(_ completionHandler: @escaping ((_ resultObject: AnyObject?, _ error: NSError?) -> Void)) {
        self.currentTask = self.session.dataTask(with: self.URLRequest, completionHandler: { (data, response, error) in
            if self.isCancelled {
                self.removeProgressObservers()
                completionHandler(nil, nil)
                return
            }
            var resultObject: AnyObject?
            if let data = data, let response = response as? HTTPURLResponse, self.HTTPMethod != ImgurHTTPMethod.Delete {
                do {
                    let JSONDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                    resultObject = try self.parseResponse(JSONDictionary, response: response)
                } catch let error as NSError {
                    self.removeProgressObservers()
                    completionHandler(nil, error)
                    return
                }
            }
            self.removeProgressObservers()
            completionHandler(resultObject, error as NSError?)
        })
        self.addProgressObservers()
        self.currentTask!.resume()
    }
    
    // MARK: - Progress
    
    internal func addProgressObservers() {
        self.updateDownloadProgress(0)
        self.updateUploadProgress(0)
        self.uploadProgressObserver = self.currentTask?.observe(\URLSessionTask.countOfBytesSent, changeHandler: { (task, _) in
            guard task.countOfBytesExpectedToSend > 0 && task.countOfBytesSent > 0 else {
                return
            }
            let progress = CGFloat(task.countOfBytesSent) / CGFloat(task.countOfBytesExpectedToSend)
            self.updateUploadProgress(progress)
        })
        self.downloadProgressObserver = self.currentTask?.observe(\URLSessionTask.countOfBytesReceived, changeHandler: { (task, _) in
            guard task.countOfBytesReceived > 0 && task.countOfBytesExpectedToReceive > 0 else {
                return
            }
            let progress = CGFloat(task.countOfBytesReceived) / CGFloat(task.countOfBytesExpectedToReceive)
            self.updateDownloadProgress(progress)
        })
    }
    
    internal func removeProgressObservers() {
        self.uploadProgressObserver?.invalidate()
        self.downloadProgressObserver?.invalidate()
        self.uploadProgressObserver = nil
        self.downloadProgressObserver = nil
        self.updateUploadProgress(1)
        self.updateDownloadProgress(1)
    }
    
    internal func updateUploadProgress(_ progress: CGFloat) {
        self.uploadProgress = progress
        self.uploadProgressHandler?(self, progress)
        
    }
    
    internal func updateDownloadProgress(_ progress: CGFloat) {
        self.downloadProgress = progress
        self.downloadProgressHandler?(self, progress)
    }
    
    // MARK: - Response methods and properties
    
    open var error: NSError?
    open var resultObject: AnyObject?
    
    internal func parseResponse(_ json: NSDictionary, response: HTTPURLResponse) throws -> AnyObject {
        return json
    }

}
