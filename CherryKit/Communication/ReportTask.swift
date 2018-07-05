//
//  ReportTask.swift
//  CherryKit
//
//  Created by Rens Verhoeven on 04-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import Foundation

open class ReportTask: Task {
    
    open let objectName: String
    open let reason: String
    
    public init(token: String, reason: String, objectName: String) {
        
        self.reason = reason
        self.objectName = objectName
        
        super.init(token: token)
    }
    
    override var request: URLRequest {
        var request = cherryRequest("reports", method: .Post)
        request.cachePolicy = NSURLRequest.CachePolicy.returnCacheDataElseLoad
        let bodyDictionary: NSMutableDictionary = ["post_id": self.objectName, "reason": self.reason]
        request.httpBody = self.postBodyWithDictionary(bodyDictionary)
        return request
    }
    
    open func postBodyWithDictionary(_ dictionary: NSDictionary) -> Data {
        return try! JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
    
    override func parseJSONData(_ data: Data) -> TaskResult {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary, (json["sucess"] as? Bool) == true {
                return TaskResult(error: nil)
            } else {
                throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Could not parse share JSON response format"])
            }
        } catch {
            return TaskResult(error: error)
        }
    }
}
