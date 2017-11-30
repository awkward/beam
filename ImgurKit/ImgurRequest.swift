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
    
    //MARK: - Operation methods
    
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
    
    //MARK: - Imgur controller
    
    internal var imgurController: ImgurController!
    
    //MARK: - Request methods and properties
    
    open var endpoint: String!
    open var parameters: [String: Any]?
    open var HTTPMethod: ImgurHTTPMethod = ImgurHTTPMethod.Get
    
    open var deleteHash: String?
    
    open var uploadProgressHandler: ((_ request: ImgurRequest, _ progress: CGFloat) -> ())?
    open var downloadProgressHandler: ((_ request: ImgurRequest, _ progress: CGFloat) -> ())?
    
    open var uploadProgress: CGFloat = 0
    open var downloadProgress: CGFloat = 0
    
    internal var currentTask: URLSessionTask?
    
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
    
    internal func performRequest(_ completionHandler: @escaping ((_ resultObject: AnyObject?, _ error: NSError?) -> ())) {
        self.currentTask = self.session.dataTask(with: self.URLRequest, completionHandler: { (data, response, error) in
            if self.isCancelled {
                self.removeProgressObservers()
                completionHandler(nil, nil)
                return
            }
            var resultObject: AnyObject?
            if let data = data, let response = response as? HTTPURLResponse , self.HTTPMethod != ImgurHTTPMethod.Delete {
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
    
    //MARK: - Progress
    
    internal func addProgressObservers() {
        self.updateDownloadProgress(0)
        self.updateUploadProgress(0)
        self.currentTask?.addObserver(self, forKeyPath: "countOfBytesSent", options: [NSKeyValueObservingOptions.initial, NSKeyValueObservingOptions.new] , context: nil)
        self.currentTask?.addObserver(self, forKeyPath: "countOfBytesReceived", options: [NSKeyValueObservingOptions.initial, NSKeyValueObservingOptions.new] , context: nil)
    }
    
    internal func removeProgressObservers() {
        self.currentTask?.removeObserver(self, forKeyPath: "countOfBytesSent")
        self.currentTask?.removeObserver(self, forKeyPath: "countOfBytesReceived")
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
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let task = object as? URLSessionTask, let keyPath = keyPath , task == self.currentTask && keyPath == "countOfBytesSent" {
            if task.countOfBytesExpectedToSend > 0 && task.countOfBytesSent > 0{
                let progress: CGFloat = CGFloat(task.countOfBytesSent)/CGFloat(task.countOfBytesExpectedToSend)
                self.updateUploadProgress(progress)
            }
        } else if let task = object as? URLSessionTask, let keyPath = keyPath , task == self.currentTask && keyPath == "countOfBytesReceived" {
            if task.countOfBytesExpectedToSend > 0 && task.countOfBytesSent > 0{
                let progress: CGFloat = CGFloat(task.countOfBytesReceived)/CGFloat(task.countOfBytesExpectedToReceive)
                self.updateDownloadProgress(progress)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    
    //MARK: - Response methods and properties
    
    open var error: NSError?
    open var resultObject: AnyObject?
    
    internal func parseResponse(_ json: NSDictionary, response: HTTPURLResponse) throws -> AnyObject {
        return json
    }

}
