//
//  CherryMultiredditParsingOperation.swift
//  beam
//
//  Created by Robin Speijer on 05-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CherryKit
import CoreData

/// This operation will fetch images for all subreddits in this multireddit collection.
class MultiredditImagesOperation: CherryPostParsingOperation {
    
    var imageURLs: [URL?]?
    
    var currentTask: MultiredditMetadataTask?

    override func start() {
        super.start()
        
        if let multireddits = self.parsingOperation?.objectCollection?.objects?.array as? [Multireddit] {
            AppDelegate.shared.managedObjectContext.performAndWait({ () -> Void in
                guard self.isCancelled == false else {
                    self.finishOperation()
                    return
                }
                var subredditSet = Set<Subreddit>()
                for multireddit in multireddits {
                    if let multiSubs = multireddit.subreddits?.allObjects as? [Subreddit] {
                        subredditSet.formUnion(Set(multiSubs))
                    }
                }
                
                if let token = self.cherryController?.accessToken, subredditSet.count > 0 {
                    let task = MultiredditMetadataTask(token: token, subredditIDs: subredditSet.filter({ $0.displayName != nil }).map({ $0.displayName! }))
                    self.currentTask = task
                    task.start({ (result: TaskResult) -> Void in
                        guard self.isCancelled == false else {
                            self.finishOperation()
                            return
                        }
                        if let multiredditResult = result as? MultiredditMetadataTaskResult {
                            self.processMetadata(multiredditResult.metadata)
                        } else {
                            self.error = result.error
                        }
                        self.finishOperation()
                    })
                } else {
                    self.finishOperation()
                }
            })
        } else {
            self.finishOperation()
        }
        
    }
    
    override func cancel() {
        super.cancel()
        self.currentTask?.cancel()
    }
    
    func processMetadata(_ metadata: MultiredditMetadata) {
        
        var groupedImageUrls = [String: URL]()
        for subreddit in metadata.subreddits {
            if let url = subreddit.imageURL {
                groupedImageUrls[subreddit.displayName] = url
            }
        }
        
        self.parsingOperation?.objectCollection?.managedObjectContext?.performAndWait {
            if let multireddits = self.parsingOperation?.objectCollection?.objects?.array as? [Multireddit] {
                self.imageURLs = multireddits.map({ (multireddit: Multireddit) -> URL? in
                    if let subreddits = multireddit.subreddits {
                        for sub in subreddits {
                            if let sub = sub as? Subreddit, let displayName = sub.displayName {
                                return groupedImageUrls[displayName]
                            }
                        }
                    }
                    return nil
                    
                })
            }
        }
        
    }
    
}
