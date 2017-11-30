//
//  MarkdownParsingOperation.swift
//  Beam
//
//  Created by Rens Verhoeven on 03-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

class MarkdownParsingOperation: DataOperation {
    
    var parsingOperation: CollectionParsingOperation? {
        return self.dependencies.first as? CollectionParsingOperation
    }
    
    override func start() {
        super.start()
        
        self.parsingOperation?.objectContext.perform {
            guard self.isCancelled == false else {
                self.finishOperation()
                return
            }
            if let contents = self.parsingOperation?.objectCollection?.objects?.array as? [Content] {
                let comments = contents.filter { $0 is Comment } as! [Comment]
                for comment in comments {
                    _ = comment.markdownString
                }
                let posts = contents.filter { $0 is Post } as! [Post]
                for post in posts {
                    _ = post.markdownString
                }
            }
            self.finishOperation()
            
        }
        
    }
    
}
