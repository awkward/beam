//
//  MultiredditMetadataTask.swift
//  CherryKit
//
//  Created by Robin Speijer on 05-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

open class MultiredditMetadataTaskResult: TaskResult {
    
    open let metadata: MultiredditMetadata
    
    init(metadata: MultiredditMetadata) {
        self.metadata = metadata
        super.init(error: nil)
    }
    
}

open class MultiredditMetadataTask: Task {
    
    open let subredditIDs: [String]
    
    public init(token: String, subredditIDs: [String]) {
        self.subredditIDs = subredditIDs
        super.init(token: token)
    }
    
    override var request: URLRequest {
        do {
            let httpBody = try JSONSerialization.data(withJSONObject: ["subreddits": self.subredditIDs], options: [])
            var cherryRequest = self.cherryRequest("multireddits", method: .Post)
            cherryRequest.httpBody = httpBody
            return cherryRequest
        } catch {
            NSLog("Cannot serialize multireddits multidata body to JSON: %@, error: %@", self.subredditIDs, error as NSError)
            fatalError()
        }
    }
    
    override func parseJSONData(_ data: Data) -> TaskResult {
        do {
            if let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject], let metadata = MultiredditMetadata(JSON: JSON) {
                return MultiredditMetadataTaskResult(metadata: metadata)
            } else {
                throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Could not parse cherry subreddit metadata format"])
            }
        } catch {
            return TaskResult(error: error as NSError)
        }
    }
    
}
