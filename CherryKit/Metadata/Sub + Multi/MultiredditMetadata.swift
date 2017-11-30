//
//  MultiredditMetadata.swift
//  CherryKit
//
//  Created by Robin Speijer on 05-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

public struct MultiredditMetadata {
    
    public var subreddits: [SubredditMetadata]
    
    init?(JSON: [String: AnyObject]) {
        if let subredditDicts = JSON["subreddits"] as? [[String: AnyObject]] {
            var subreddits = [SubredditMetadata]()
            
            for dict in subredditDicts {
                if let subreddit = SubredditMetadata(JSON: dict) {
                    subreddits.append(subreddit)
                }
            }
            
            self.subreddits = subreddits
        } else {
            return nil
        }
    }
    
}
