//
//  UserSettings.swift
//  Beam
//
//  Created by Rens Verhoeven on 07/02/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

// MARK: - Shared instance

/// The user settings that are either chanable in a dedicated Settings View, or changed by the app based on a user'ss action.
/// To use a UserSetting, simply define the key below and then use `UserSettings[.KEY]` to get the value or use `UserSettings[.KEY] = VALUE` to set the value.
public let UserSettings = Settings(allKeys: [
    .analyticsProfileToken,
    .announcementNotificationsEnabled,
    .appOpen,
    .autoPlayGifsEnabled,
    .autoPlayGifsEnabledOnCellular,
    .browser,
    .cherryAdminUsers,
    .cherryImageURLPatterns,
    .nightModeEnabled,
    .nightModeAutomaticEnabled,
    .nightModeAutomaticThreshold,
    .userHasDonated,
    .hasBeenShownTheAddAccountWarning,
    .hasBeenShownTheWelcomeScreen,
    .redditMessageNotificationsEnabled,
    .notificationsBadgeCount,
    .notifiedMessages,
    .playSounds,
    .postMarking,
    .postMediaOverViewLayout,
    .prefersSafariViewControllerReaderMode,
    .privateBrowserWarningShown,
    .shopNotificationsEnabled,
    .shownBanners,
    .showPostMetadata,
    .showPostMetadataDate,
    .showPostMetadataDomain,
    .showPostMetadataGilded,
    .showPostMetadataLocked,
    .showPostMetadataStickied,
    .showPostMetadataSubreddit,
    .showPostMetadataUsername,
    .showSpoilerOverlay,
    .showPrivacyOverlay,
    .privacyModeEnabled,
    .subredditsPrivacyOverlaySetting,
    .subredditsSpoilerOverlaySetting,
    .subredditsThumbnailSetting,
    .subscriptionsListType,
    .thumbnailsViewType,
    .youTubeApp,
    .firstLaunchDate,
    .lastAppReviewRequestDate
])

// MARK: - Settings Keys

///IMPORTANT: All keys defined here have to be included when initializing UserSettings. Especially keys with a default value!
extension SettingsKeys {
    
    /// The anonymous token used to identify the user to analytics services
    static let analyticsProfileToken = SettingsKey<String?>("AnalyticsProfileToken")
    
    /// If announcement notifications are enabled
    static let announcementNotificationsEnabled = SettingsKey<Bool>("AnnouncementNotifications", defaultValue: true)
    
    /// The current (on app open) option, also known as the default launch screen
    static let appOpen = SettingsKey<AppLaunchOption>("OnAppLaunchOption", defaultValue: AppLaunchOption.defaultAppLaunchOption)
    
    /// If GIF images should auto-start playing in a subreddit. This only works if the display pack has been purchased
    static let autoPlayGifsEnabled = SettingsKey<Bool>("AutoPlayGifs", defaultValue: true)
    
    /// If GIF images should auto-start when the user is on a cellular network
    static let autoPlayGifsEnabledOnCellular = SettingsKey<Bool>("AutoPlayGifsOnCellular", defaultValue: false)
    
    /// The current "browser" option the use has chosen, this is used for opening links
    static let browser = SettingsKey<ExternalLinkOpenOption>("CurrentBrowser", defaultValue: ExternalLinkOpenOption.inApp)
    
    /// The admin users that have been defined in the feature flags. These admins get all packs for free
    static let cherryAdminUsers = SettingsKey<[String]?>("CherryAdminUsers")
    
    /// The NSRegularExpression patterns that are defined in the feature flags. These are used to detect image links that should be parsed on the cherry server
    static let cherryImageURLPatterns = SettingsKey<[String]>("CherryImageURLPatterns", defaultValue: ["^https?://.*imgur.com/", "^https?://(?: www.)?gfycat.com/", "(.jpe?g|.png|.gif)"])
    
    /// If the manual night mode is enabled
    static let nightModeEnabled = SettingsKey<Bool>("DarkModeActive", defaultValue: false)
    
    /// If automatic night mode is enabled
    static let nightModeAutomaticEnabled = SettingsKey<Bool>("DarkModeAutomatic", defaultValue: false)
    
    /// The screen brightness threshold set by the user. Used to determine when automatic night mode should kick in
    static let nightModeAutomaticThreshold = SettingsKey<Float>("DarkModeAutomaticThreshold", defaultValue: 0.4)
    
    /// If the user has donated from the app
    static let userHasDonated = SettingsKey<Bool>("HasDonated", defaultValue: false)
    
    /// If the user was shown the "Quick change" alert before adding a second account
    static let hasBeenShownTheAddAccountWarning = SettingsKey<Bool>("HasShownAddAccountWarning", defaultValue: false)
    
    /// If the user has been shown the welcome screen, which is shown for the first time
    static let hasBeenShownTheWelcomeScreen = SettingsKey<Bool>("HasShownWelcomeView", defaultValue: false)
    
    /// If notifications for reddit messages is enabled
    static let redditMessageNotificationsEnabled = SettingsKey<Bool>("MessageNotifications", defaultValue: true)
    
    /// The current number of notifications that have been send. These are not a number of reddit notification
    static let notificationsBadgeCount = SettingsKey<Int>("NotificationsBadgeCount")
    
    /// A list of identifiers of messages the user has been notified of (received a local notification)
    static let notifiedMessages = SettingsKey<[String]?>("NotifiedMessages")
    
    /// If the app should play sounds or not
    static let playSounds = SettingsKey<Bool>("PlaySounds", defaultValue: true)
    
    /// If posts that have been visited or viewed should be marked as "read"
    static let postMarking = SettingsKey<Bool>("PostMarking", defaultValue: true)
    
    /// The last selected option for the post media overview layout. 0: list 1: grid
    static let postMediaOverViewLayout = SettingsKey<Int>("PostMediaOverViewLayout", defaultValue: 1)
    
    /// If the user prefers to open links in the Reader View of SFSafariViewController
    static let prefersSafariViewControllerReaderMode = SettingsKey<Bool>("PrefersReaderMode", defaultValue: false)
    
    /// If the user has been shown the private browser warning when the user is in privacy mode
    static let privateBrowserWarningShown = SettingsKey<Bool>("PrivateBrowserWarningShown", defaultValue: false)
    
    /// If shop notifications are enabled
    static let shopNotificationsEnabled = SettingsKey<Bool>("ShopNotifications", defaultValue: true)
    
    /// A list of identifiers of subreddit list banners that the user has visited or closed
    static let shownBanners = SettingsKey<[String]?>("ShownBanners")
    
    /// If metadata should be shown on posts
    static let showPostMetadata = SettingsKey<Bool>("ShowPostMetadata", defaultValue: true)
    
    /// If metadata shown for posts should include the date
    static let showPostMetadataDate = SettingsKey<Bool>("ShowPostMetadataDate", defaultValue: true)
    
    /// If metadata shown for posts should include the domain (thumbnail mode only)
    static let showPostMetadataDomain = SettingsKey<Bool>("ShowPostMetadataDomain", defaultValue: true)
    
    /// If metadata shown for posts should include the gilded status
    static let showPostMetadataGilded = SettingsKey<Bool>("ShowPostMetadataGilded", defaultValue: true)
    
    /// If metadata shown for posts should include the locked or archived status
    static let showPostMetadataLocked = SettingsKey<Bool>("ShowPostMetadataLocked", defaultValue: true)
    
    /// If metadata shown for posts should include the sticked status
    static let showPostMetadataStickied = SettingsKey<Bool>("ShowPostMetadataStickied", defaultValue: true)
    
    /// If metadata shown for posts should include the subreddit name
    static let showPostMetadataSubreddit = SettingsKey<Bool>("ShowPostMetadataSubreddit", defaultValue: true)
    
    /// If metadata shown for posts should include the author's username
    static let showPostMetadataUsername = SettingsKey<Bool>("ShowPostMetadataUsername", defaultValue: true)
    
    /// General setting to determine if the spoiler overlay should be shown
    static let showSpoilerOverlay = SettingsKey<Bool>("ShowSpoilerOverlay", defaultValue: true)
    
    /// General setting to determine if the privacy (NSFW) overlay should be shown
    static let showPrivacyOverlay = SettingsKey<Bool>("ShowPrivacyOverlay", defaultValue: true)
    
    /// The status of the privacy mode
    static let privacyModeEnabled = SettingsKey<Bool>("StealthModeEnabled", defaultValue: false)
    
    /// An dictionary of identifiers (subreddit) and NSNumbers (bool) if the privacy overlay should be shown for that subreddit
    static let subredditsPrivacyOverlaySetting = SettingsKey<[String: NSNumber]?>("SubredditsPrivacyOverlaySetting")
    
    /// An dictionary of identifiers (subreddit) and NSNumbers (bool) if the spoiler overlay should be shown for that subreddit
    static let subredditsSpoilerOverlaySetting = SettingsKey<[String: NSNumber]?>("SubredditsSpoilerOverlaySetting")
    
    /// An dictionary of identifiers (subreddit) and strings (ThumbnailType) with the thumbnail setting for each subreddit
    static let subredditsThumbnailSetting = SettingsKey<[String: String]?>("SubredditsThumbnailSetting")
    
    /// The last used subreddits list type `subreddits` or `multireddits`
    static let subscriptionsListType = SettingsKey<String>("SubscriptionsListType", defaultValue: "subreddits")
    
    /// General setting for the thumbnail view type
    static let thumbnailsViewType = SettingsKey<ThumbnailsViewType>("ThumbnailsViewType", defaultValue: ThumbnailsViewType.large)
    
    /// The YouTube app that should be used to open youtube links
    static let youTubeApp = SettingsKey<ExternalLinkOpenOption>("CurrentYouTubeApp", defaultValue: ExternalLinkOpenOption.inApp)
    
    /// The date the app was first launched
    static let firstLaunchDate = SettingsKey<Date?>("AppInstallDate")
    
    /// The date the app has last requested for a review popup
    static let lastAppReviewRequestDate = SettingsKey<Date?>("LastAppReviewRequestDate")
    
}
