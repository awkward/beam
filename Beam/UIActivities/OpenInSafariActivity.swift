//
//  OpenInSafariActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 01-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

final class OpenInSafariActivity: UIActivity {
    
    fileprivate var post: Post?
    fileprivate var comment: Comment?
    fileprivate var subreddit: Subreddit?
    
    fileprivate var url: URL? {
        if let postPermalink = self.post?.permalink {
            let urlString = "https://\((AppDelegate.shared.authenticationController.configuration.regularHost as NSString).appendingPathComponent(postPermalink))"
            return URL(string: urlString as String)
        }
        if let subredditPermalink = self.subreddit?.permalink {
            let urlString = "https://\((AppDelegate.shared.authenticationController.configuration.regularHost as NSString).appendingPathComponent(subredditPermalink))"
            return URL(string: urlString as String)
        }
        if let commentPermalink = self.comment?.permalink {
            let urlString = "https://\((AppDelegate.shared.authenticationController.configuration.regularHost as NSString).appendingPathComponent(commentPermalink))"
            return URL(string: urlString as String)
        }
        if let subredditPermalink = self.post?.subreddit?.permalink {
            let urlString = "https://\((AppDelegate.shared.authenticationController.configuration.regularHost as NSString).appendingPathComponent(subredditPermalink))"
            return URL(string: urlString as String)
        }
        return self.foundURL
    }
    
    fileprivate var foundURL: URL?
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.open-in-safari")
    }
    
    override var activityTitle: String? {
        return AWKLocalizedString("open-in-safari")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "open_in_safari_activity_icon")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if  item is Post || item is Subreddit || item is Comment || item is NSURL {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if item is Post {
                self.post = item as? Post
            }
            if item is Subreddit {
                self.subreddit = item as? Subreddit
            }
            if item is Comment {
                self.comment = item as? Comment
            }
            if item is Foundation.URL {
                self.foundURL = item as? Foundation.URL
            }
        }
    }
    
    override func perform() {
        if let url = self.url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
}
