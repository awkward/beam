//
//  RedditListingRequest.swift
//  Snoo
//
//  Created by Robin Speijer on 18-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class RedditCollectionRequest: RedditRequest {
    
    var query: CollectionQuery
    var after: String?
    
    init(query: CollectionQuery, authenticationController: AuthenticationController) {
        self.query = query
        super.init(authenticationController: authenticationController)
    }
    
    override var urlRequest: URLRequest? {
        get {
            
            if let requestURL = URL(string: "\(self.query.apiPath)", relativeTo: self.baseURL as URL), var URLComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: true) {
                var queryItems = [URLQueryItem]()
                if let exisitingQueryItems = URLComponents.queryItems {
                    queryItems.append(contentsOf: exisitingQueryItems)
                }
                if let moreQueryItems = self.query.apiQueryItems {
                    queryItems.append(contentsOf: moreQueryItems)
                }
                if let after = self.after {
                    queryItems.append(URLQueryItem(name: "after", value: after))
                }
                //If the queryItems are set but zero, URLComponents adds a question mark to the URL which is unwanted
                if queryItems.count > 0 {
                    URLComponents.queryItems = queryItems
                }
                if let url = URLComponents.url {
                    return URLRequest(url: url)
                }
            }
            return nil
        }
        set {
            // We made a generated property out of a computed property in the superclass. So set will ignore the new value.
        }
    }
    
}
