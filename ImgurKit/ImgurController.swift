//
//  ImgurController.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

public class ImgurController: NSObject {
    
    open var clientID: String!
    
    open var useMashapeAPI: Bool = false
    open var mashapeKey: String?
    
    fileprivate var requestsQeue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    lazy fileprivate var requestExecutionHandlerQueue: DispatchQueue = {
        return DispatchQueue(label: "com.madeawkward.imgurkit-execution-handler", attributes: DispatchQueue.Attributes.concurrent)
    }()
    
    fileprivate func meetsRequirements() -> Bool {
        if self.clientID == nil {
            return false
        }
        if self.useMashapeAPI && self.mashapeKey == nil {
            return false
        }
        return true
    }
    
    open func executeRequests(_ requests: [ImgurRequest], uploadProgressHandler: ((_ requestNumber: Int, _ totalProgress: CGFloat) -> Void)?, completionHandler: @escaping ((_ error: NSError?) -> Void)) {
       
        self.requestExecutionHandlerQueue.async {
            for request in requests {
                if uploadProgressHandler != nil {
                    request.uploadProgressHandler = { (request: ImgurRequest, progress: CGFloat) in
                        var requestNumber = 0
                        if let index = requests.index(of: request) {
                            requestNumber = index + 1
                        }
                        var totalProgress: CGFloat = 0
                        for request in requests {
                            totalProgress += request.uploadProgress
                        }
                        totalProgress /= CGFloat(requests.count)
                        uploadProgressHandler!(requestNumber, totalProgress)
                    }
                }
                request.imgurController = self
            }
            self.requestsQeue.addOperations(requests, waitUntilFinished: true)
            var errors = [NSError]()
            for request in requests {
                if let error = request.error {
                    errors.append(error)
                }
            }
            completionHandler(errors.first)
        }
        
    }
    
    internal var APIURL: URL {
        if self.useMashapeAPI && self.mashapeKey != nil {
            return URL(string: "https://imgur-apiv3.p.mashape.com/3/")!
        }
        return URL(string: "https://api.imgur.com/3/")!
    }
    
    lazy var URLSession: Foundation.URLSession = {
        let configuration = URLSessionConfiguration.default
        
        var headers = [String: String]()
        if let identifier = self.clientID {
            headers["Authorization"] = "Client-ID \(identifier)"
        }

        headers["Accept"] = "application/json"
        if let mashapeKey = self.mashapeKey {
            headers["X-Mashape-Key"] = mashapeKey
        }
        configuration.httpAdditionalHeaders = headers
        
        return Foundation.URLSession(configuration: configuration)
    }()

}
