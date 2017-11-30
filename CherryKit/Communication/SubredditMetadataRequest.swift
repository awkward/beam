//
//  SubredditMetadataRequest.swift
//  CherryKit
//
//  Created by Robin Speijer on 16-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

open class SubredditMetadataTaskResult: TaskResult {
    
    open let metadata: SubredditMetadata
    
    init(metadata: SubredditMetadata) {
        self.metadata = metadata
        super.init(error: nil)
    }
    
}

open class SubredditMetadataTask: Task {
    
    open let subredditID: String
    
    public init(token: String, subredditID: String) {
        self.subredditID = subredditID
        super.init(token: token)
    }
    
    override var request: URLRequest {
        return self.cherryRequest("subreddits/\(self.subredditID)", method: .Post)
    }
    
    override func parseJSONData(_ data: Data) -> TaskResult {
        do {
            if let JSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject], let metadata = SubredditMetadata(JSON: JSON) {
                return SubredditMetadataTaskResult(metadata: metadata)
            } else {
                throw NSError(domain: CherryKitErrorDomain, code: CherryKitParsingErrorCode, userInfo: [NSLocalizedDescriptionKey: "Could not parse cherry subreddit metadata format"])
            }
        } catch {
            return TaskResult(error: error)
        }
    }

}
