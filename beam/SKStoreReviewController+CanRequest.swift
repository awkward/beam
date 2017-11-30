//
//  SKStoreReviewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 31/05/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import StoreKit
import Snoo

@available(iOS 10.3, *)
extension SKStoreReviewController {
    
    /// Checks a number of variables and returns if the app can request for a app review
    ///
    /// - Parameter subreddit: The subreddit the user is when you are about to request a review
    /// - Returns: If a request for a review should be made
    public class func canRequestReview(with subreddit: Subreddit?) -> Bool {
        guard let firstLaunchDate = UserSettings[.firstLaunchDate], Date().timeIntervalSince(firstLaunchDate) > 432000 else {
            //We only ask for a review if the app was first launched 5 days ago
            return false
        }
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            //We only want real reddit users to review us, this means they will have an account.
            return false
        }
        guard subreddit?.identifier != Subreddit.frontpageIdentifier && subreddit?.identifier != Subreddit.allIdentifier else {
            //Only users that visit other subreddits or multireddits should
            return false
        }
        guard RedditActivityController.recentlyVisitedSubreddits.count > 3 else {
            //We want a user that has used the app more than just a few seconds, so we wait with a review until they've viewed 3 different subreddits.
            //Also people that are in privacy mode, won't have any recently visited subreddits
            return false
        }
        //We only ask for a request again if it has been 3 days since the last request
        return Date().timeIntervalSince(UserSettings[.lastAppReviewRequestDate] ?? Date(timeIntervalSince1970: 0)) > 259200
    }
    
}
