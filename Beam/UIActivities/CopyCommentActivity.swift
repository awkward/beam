//
//  CopyCommentActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 03-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import RedditMarkdownKit

final class CopyCommentActivity: CustomObjectActivity<Comment> {

    fileprivate var comment: Comment?
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.copy-comment")
    }
    
    override var activityTitle: String? {
        return AWKLocalizedString("copy-comment-activity-title")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "copy_activity_icon")
    }
    
    override func perform() {
        super.perform()
        UIPasteboard.general.string = self.object?.markdownString?.attributedStringWithStylesheet(MarkdownStylesheet.beamCommentsStyleSheet()).string
    }
    
}
