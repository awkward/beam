//
//  StreamImagesOperation.swift
//  beam
//
//  Created by Robin Speijer on 05-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CherryKit
import CoreData

class StreamImagesOperation: CherryPostParsingOperation {
    
    /// Defines the minimum aspect ratio of an image in order for it to be displayed inline
    static var minimumAspectRatio: CGFloat = 0.1
    
    var currentTask: ImageMetadataTask?
    
    override func start() {
        super.start()
        
        guard !Config.CherryAppVersionKey.isEmpty else {
            self.finishOperation()
            return
        }
        
        self.parsingOperation?.objectContext.perform {
            guard self.isCancelled == false else {
                self.finishOperation()
                return
            }
            if self.cherryController?.accessToken == nil {
                self.cherryController?.prepareAuthorization()
            }
            
            if let contents = self.parsingOperation?.objectCollection?.objects?.array as? [Content], let accessToken = self.cherryController?.accessToken {
                let posts = contents.filter { $0 is Post } as! [Post]
                let imageRequests = self.imageMetadataRequestsForPosts(posts)
                
                if imageRequests.count > 0 {
                    let task = ImageMetadataTask(token: accessToken, imageRequests: imageRequests)
                    self.currentTask = task
                    task.start({ (result: TaskResult) -> Void in
                        guard self.isCancelled == false else {
                            self.finishOperation()
                            return
                        }
                        if let result = result as? ImageMetadataTaskResult, result.metadata.count > 0 {
                            self.parsingOperation?.objectContext.performAndWait {
                                self.insertMediaObjectsArray(result.metadata, posts: posts)
                            }
                        } else if let error = result.error as NSError? {
                            if error.domain == NSURLErrorDomain && error.code == 401 {
                                AppDelegate.shared.cherryController.prepareAuthorization()
                            }
                        }
                        
                        self.finishOperation()
                    })
                } else {
                    self.finishOperation()
                }
            } else {
                self.finishOperation()
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        self.currentTask?.cancel()
        
    }
    
    fileprivate func imageMetadataRequestsForPosts(_ posts: [Post]) -> [CherryKit.ImageRequest] {
        
        let imagePosts = posts.filter { (post: Post) -> Bool in
            let imageURLPatterns: [String]? = self.cherryController?.features?.imageURLPatterns.filter({
                let pattern: String = $0
                //Filter reddit media patterns that we handle locally
                if pattern.contains("redditmedia") || pattern.contains("reddituploads") || pattern.contains("redd.it") {
                    return false
                }
                return true
            })
            if let patterns: [String] = imageURLPatterns {
                guard post.urlString != nil && post.identifier != nil else {
                    return false
                }
                //Skip posts that already have media objects and are not imgur, imgur links might have an updated album or text
                if let mediaObjects = post.mediaObjects, mediaObjects.count > 0 && post.urlString?.lowercased().contains("imgur.com") == false {
                    return false
                }
                
                for pattern in patterns {
                    do {
                        let regex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpression.Options.caseInsensitive])
                        if let match = regex.firstMatch(in: post.urlString!, options: [], range: NSRange(location: 0, length: (post.urlString! as NSString).length)) {
                            if match.numberOfRanges > 0 {
                                return true
                            }
                        }
                    } catch {
                        NSLog("Error while checking post URL for regex: \(error)")
                    }
                }
            }
            return false
        }
        
        return imagePosts.map { (post: Post) -> CherryKit.ImageRequest in
            return ImageRequest(postID: post.identifier!, imageURL: post.urlString!)
        }
    }
    
    fileprivate func insertMediaObjectsArray(_ responses: [ImageResponse], posts: [Post]) {
        for postImageResponse in responses {
            if let post = posts.first(where: { (post) -> Bool in
                return post.identifier == postImageResponse.request.postID
            }) {
                post.insertMediaObjects(with: postImageResponse)
                
            }
        }
    }

}
