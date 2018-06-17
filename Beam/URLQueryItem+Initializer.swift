//
//  URLQueryItem+Initializer.swift
//  Beam
//
//  Created by Rens Verhoeven on 11/01/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import Foundation

extension URLQueryItem {
    
    /// Creates a URLQueryItem with a reddit query. This means the value replaces spaces for `+` symbols. Especially usefull for search
    ///
    /// - Parameters:
    ///   - name: Name of the query parameters
    ///   - value: The reddit query, for instance a search query.
    ///   - allowColon: If having a colon is allowed in the reddit query, shouldn't be allowed for subreddit queries.
    init(name: String, redditQuery value: String, allowColon: Bool = true) {
        var escapedValue = value.replacingOccurrences(of: " ", with: "+")
        if !allowColon {
            //Reddit API fix, if the search keywords for subreddits contain a colon, the request will return posts instead.
            //We replace the colon with a space, so that the keywords are still used.
            escapedValue = value.replacingOccurrences(of: ":", with: " ")
        }
        self.init(name: name, value: escapedValue)
    }
    
}
