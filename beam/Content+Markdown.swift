//
//  Content+Markdown.swift
//  beam
//
//  Created by Robin Speijer on 20-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import Snoo
import RedditMarkdownKit

private var ContentMarkdownStringAssociationKey: UInt8 = 0

extension Content {
    
    var markdownString: MarkdownString? {
        get {
            if let markdownString = objc_getAssociatedObject(self, &ContentMarkdownStringAssociationKey) as? MarkdownString {
                return markdownString
            } else if let content = content {
                let newMarkdownString = MarkdownString(string: content)
                self.markdownString = newMarkdownString
                return newMarkdownString
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self, &ContentMarkdownStringAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}
