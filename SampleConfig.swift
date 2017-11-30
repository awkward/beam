//
//  Config.swift
//  Beam
//
//  Created by Rens Verhoeven on 30/05/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit
import Trekker

/// General configuration parameters for use throughout the app.
struct Config {
    
    /// The Apple app identifier for the app store.
    static let appleAppID = "937987469"
    
    /// The ID for the reddit client, registered at reddit.com.
    static let redditClientID = "YOUR REDDIT CLIENT ID"
    
    /// The client ID to communicate with the imgur API.
    static let imgurClientID = "YOUR IMGUR CLIENT ID"
    
    // MARK: - Optionally editable parameters
    
    /// The name of the client communicating with the reddit API.
    static let redditClientName = "Beam"
    
    /// The URL reddit should redirect to when the oAuth flow ends.
    static let redditRedirectURL = "beam://127.0.0.1/authorized"
    
    /// The URL scheme that is used for links to subreddits that are used in the app.
    static let internalURLScheme = "beamwtf"
    
    /// The version of the app that is reported to the cherry API.
    static let cherryAppVersion = "2.0"
    
    // This is a key used by our internal API. There is no way to use this API. This key can be left empty. When the key is empty, images won't be shown inline.
    static let CherryAppVersionKey = ""
    
    static func createAnalyticsServices() -> [TrekkerService] {
        return [MixpanelAnalyticsService(token: "b0ff5c688c9d6e7c3cdae069646427dc")]
    }
}
