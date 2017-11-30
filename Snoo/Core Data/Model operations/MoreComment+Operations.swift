//
//  MoreComment+Operations.swift
//  Snoo
//
//  Created by Rens Verhoeven on 29-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import CoreData

extension MoreComment {
    
    public func moreChildrenOperation(_ post: Post, sort: CollectionSortType, commentsCollectionID: NSManagedObjectID, authenticationcontroller: AuthenticationController) -> [Operation]? {
        guard post.objectName != nil && self.children != nil else {
            return nil
        }
        let redditRequest = RedditRequest(authenticationController: authenticationcontroller)
        redditRequest.urlSession = authenticationcontroller.userURLSession
        let commentURL = URL(string: "/api/morechildren", relativeTo: redditRequest.baseURL as URL)!
        var commentURLComponents = URLComponents(url: commentURL, resolvingAgainstBaseURL: true)
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "api_type", value: "json"))
        commentURLComponents?.queryItems = queryItems
        
        if let url = commentURLComponents?.url {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = DataRequest.formPOSTDataWithParameters(["children": self.children!, "link_id": post.objectName!, "api_type": "json"])
            redditRequest.urlRequest = urlRequest
        }
        
        if let context = self.managedObjectContext {
            let parsingOperation = ThingsParsingOperation(request: redditRequest, context: context)
            parsingOperation.addDependency(redditRequest)
            
            let blockOperation = BlockOperation(block: { () -> Void in
                guard let things = parsingOperation.things, things.count > 0 else {
                    return
                }
                self.managedObjectContext?.performAndWait({
                    let commentsCollection = self.managedObjectContext?.object(with: commentsCollectionID) as? ObjectCollection
                    let commentsCollectionSet = commentsCollection?.objects?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
                    if let replies = self.parent?.replies as? NSMutableOrderedSet {
                        replies.remove(self)
                        self.parent?.replies = replies
                    } else {
                        commentsCollectionSet.remove(self)
                    }
                    
                    if let comments = parsingOperation.things as? [Comment] {
                        
                        for comment in comments {
                            if let parent = comment.parent {
                                let replies = parent.replies?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet(capacity: 1)
                                replies.add(comment)
                                parent.replies = replies
                            } else {
                                commentsCollectionSet.add(comment)
                            }
                        }
                    }
                    commentsCollection?.objects = commentsCollectionSet
                })
            })
            blockOperation.addDependency(parsingOperation)
            
            return [redditRequest, parsingOperation, blockOperation]
        } else {
            return nil
        }
    }
}
