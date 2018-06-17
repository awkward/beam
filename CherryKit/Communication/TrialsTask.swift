//
//  TrialsTask.swift
//  Beam
//
//  Created by Rens Verhoeven on 19-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

open class ProductTrial: NSObject {
    open let productIdentifier: String
    open let expirationDate: Date
    open let valid: Bool
    open var expiredWarningShown: Bool = false
    
    public init?(dictionary: [String: AnyObject]) {
        
        if let identifier = dictionary["name"] as? String, let endDateTimeStamp = dictionary["ends_at"] as? Double, let valid = dictionary["is_valid"] as? Bool {
            self.productIdentifier = identifier
            self.expirationDate = Date(timeIntervalSince1970: endDateTimeStamp)
            self.valid = valid
            if let warningShownNumber: NSNumber = dictionary["expired_warning_shown"] as? NSNumber {
                let warningShown = warningShownNumber.boolValue
                self.expiredWarningShown = warningShown
            }
        } else {
            return nil
        }
    }
    
    open func dictionaryRepresentation() -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        dictionary["name"] = self.productIdentifier as AnyObject?
        dictionary["ends_at"] = self.expirationDate.timeIntervalSince1970 as AnyObject?
        dictionary["is_valid"] = self.valid as AnyObject?
        dictionary["expired_warning_shown"] = NSNumber(value: self.expiredWarningShown as Bool)
        return dictionary
    }
    
    open func currentlyActive() -> Bool {
        print("Time since now \(self.expirationDate.timeIntervalSinceNow)")
        return self.valid == true && self.expirationDate.timeIntervalSinceNow > 0
    }
}

open class TrialsTaskResult: TaskResult {
    open var trials: [ProductTrial]
    
    init(trials: [ProductTrial]) {
        self.trials = trials
        super.init(error: nil)
    }
}

open class StartTrialTask: TrialsTask {
    
    let packName: String
    
    public init(token: String, deviceToken: String, packName: String) {
        self.packName = packName
        super.init(token: token, deviceToken: deviceToken)
    }

    override var request: URLRequest {
        do {
            let httpBody = try JSONSerialization.data(withJSONObject: ["receipt_id": self.deviceToken, "name": self.packName], options: [])
            var request = self.cherryRequest("trials", method: .Post)
            request.httpBody = httpBody
            return request
        } catch {
            NSLog("Cannot serialize trails multidata body to JSON error: %@", error as NSError)
            fatalError()
        }
    }
    
}

open class TrialsTask: Task {
    
    let deviceToken: String
    
    public init(token: String, deviceToken: String) {
        self.deviceToken = deviceToken
        super.init(token: token)
    }
    
    override var request: URLRequest {
        return self.cherryRequest("trials/\(self.deviceToken)", method: .Get)
    }
    
    override func parseJSONData(_ data: Data) -> TaskResult {
        do {
            if let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject], let trialsInfo = JSON["trials"] as? [[String: AnyObject]] {
                var trials = [ProductTrial]()
                for trialInfo in trialsInfo {
                    if let trial = ProductTrial(dictionary: trialInfo) {
                        trials.append(trial)
                    }
                    
                }
                return TrialsTaskResult(trials: trials)
            } else {
                throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Could not parse cherry trials information format"])
            }
        } catch {
            return TaskResult(error: error)
        }
    }
    
}
