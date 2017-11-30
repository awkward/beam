//
//  SnooOperation.swift
//  Snoo
//
//  Created by Robin Speijer on 09-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

open class SnooOperation: Operation {
    
    open var error: Error?
    
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
     Start the Operation. This method will notify KVO that "isExecuting" has changed.
     */
    fileprivate func startOperation() {
        self.operationIsExecuting = true
    }
    
    /**
     Cancel the Operation. This method will notify KVO that "isCancelled" has changed.
     */
    open func cancelOperation() {
        self.operationIsCancelled = true
    }
    
    /**
     Finish the Operation. This method will notify KVO that "isFinished" has changed.
     */
    open func finishOperation() {
        self.operationIsFinished = true
    }
    
    override open func start() {
        self.startOperation()
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

}
