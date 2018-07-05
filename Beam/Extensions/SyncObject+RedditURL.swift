//
//  SyncObject+RedditURL.swift
//  Beam
//
//  Created by Rens Verhoeven on 11/10/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

extension SyncObject {

    var redditUrl: URL? {
        if let subreddit = self as? Subreddit, let permalink = subreddit.permalink, let url = URL(string: "https://\((AppDelegate.shared.authenticationController.configuration.regularHost as NSString).appendingPathComponent(permalink))") {
            return url
        } else if let comment = self as? Comment, let postPermalink = comment.post?.permalink, let commentIdentifier = comment.identifier, let url = URL(string: "https://\((AppDelegate.shared.authenticationController.configuration.regularHost as NSString).appendingPathComponent("\(postPermalink)/\(commentIdentifier)"))") {
            return url
        } else if let post = self as? Post, let permalink = post.permalink, let url = URL(string: "https://\((AppDelegate.shared.authenticationController.configuration.regularHost as NSString).appendingPathComponent(permalink))") {
            return url
        }
        return nil
    }
    
}
