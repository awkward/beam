//
//  AppLaunchOption.swift
//  Beam
//
//  Created by Rens Verhoeven on 08/02/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

/// The view that can be added to AppLaunchOption to open directly after the app opens
public enum AppLaunchView: String {
    case Subreddits = "subreddits"
    case Multireddits = "multireddits"
    case Messages = "messages"
    case Profile = "profile"
    case Frontpage = "frontpage"
    case All = "All"
    case LastVisitedSubreddit = "last_visited_subreddit"
}

/// The option the user has chose to open the app with, has a title (for display in settings) and a view to open
public struct AppLaunchOption: Equatable {
    public var title: String
    public var view: AppLaunchView
    
    private init(title: String, view: AppLaunchView) {
        self.title = title
        self.view = view
    }
    
    public init(dictionary: [String: String]) {
        self.title = dictionary["title"]!
        self.view = AppLaunchView(rawValue: dictionary["view_key"]!)!
    }
    
    public func dictionaryRepresentation() -> [String: String] {
        return ["view_key": self.view.rawValue, "title": self.title]
    }
    
    public static func supportedAppLaunchOptions() -> [String: [AppLaunchOption]] {
    return [
            "view": [
                AppLaunchOption(title: AWKLocalizedString("app-open-option-subreddits"), view: AppLaunchView.Subreddits),
                AppLaunchOption(title: AWKLocalizedString("app-open-option-multireddits"), view: AppLaunchView.Multireddits),
                AppLaunchOption(title: AWKLocalizedString("app-open-option-messages"), view: AppLaunchView.Messages),
                AppLaunchOption(title: AWKLocalizedString("app-open-option-profile"), view: AppLaunchView.Profile)
            ],
            "subreddit": [
                AppLaunchOption(title: AWKLocalizedString("app-open-option-last-visited-subreddit"), view: AppLaunchView.LastVisitedSubreddit),
                AppLaunchOption(title: AWKLocalizedString("app-open-option-frontpage"), view: AppLaunchView.Frontpage),
                AppLaunchOption(title: AWKLocalizedString("app-open-option-all"), view: AppLaunchView.All)
            ]
        ]
    }
    
    public static var defaultAppLaunchOption: AppLaunchOption {
        guard let defaultOption = self.supportedAppLaunchOptions()["view"]?.first else {
            assert(false, "Default app open option not found, please update this method!")
            return AppLaunchOption(title: AWKLocalizedString("app-open-option-subreddits"), view: AppLaunchView.Subreddits)
        }
        return defaultOption
    }
}

public func == (lhs: AppLaunchOption, rhs: AppLaunchOption) -> Bool {
    return lhs.view == rhs.view
}
