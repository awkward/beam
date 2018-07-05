//
//  Subreddit+Markdown.swift
//  beam
//
//  Created by Rens Verhoeven on 19-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import Snoo
import RedditMarkdownKit

private var SubredditMarkdownStringAssociationKey: UInt8 = 0

extension Subreddit {
    
    var descriptionTextMarkdownString: MarkdownString? {
        get {
            if let markdownString = objc_getAssociatedObject(self, &SubredditMarkdownStringAssociationKey) as? MarkdownString {
                return markdownString
            } else if let content = self.descriptionText {
                let newMarkdownString = MarkdownString(string: content)
                self.descriptionTextMarkdownString = newMarkdownString
                return newMarkdownString
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self, &SubredditMarkdownStringAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
