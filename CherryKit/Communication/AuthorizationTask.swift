//
//  AuthorizationRequest.swift
//  CherryKit
//
//  Created by Robin Speijer on 16-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

open class AuthorizationTaskResult: TaskResult {
    open let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
        super.init(error: nil)
    }
}

open class AuthorizationTask: Task {
    
    override var request: URLRequest {
        var request = cherryRequest("hello", method: RequestMethod.Post)
        let UUID = UIDevice.current.identifierForVendor?.uuidString ?? Foundation.UUID().uuidString
        let parameters = ["version": Cherry.appVersion ?? "2.0", "vendor_id": UUID]
        let body = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        request.httpBody = body
        return request
    }
    
    public init() {
        super.init(token: "")
    }
    
    override func parseJSONData(_ data: Data) -> TaskResult {
        do {
            guard let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Could not parse JSON object"])
            }
            if let accessToken = JSON["access_token"] as? String {
                return AuthorizationTaskResult(accessToken: accessToken)
            } else if let message = JSON["message"] as? String {
                throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: message])
            } else {
                throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Could not parse JSON object"])
            }
        } catch {
            return TaskResult(error: error as NSError)
        }
    }
    
}
