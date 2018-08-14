//
//  AppDelegate.swift
//  beam
//
//  Created by Robin Speijer on 22-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import SafariServices
import CoreData
import CherryKit
import AWKGallery
import JLRoutes
import Trekker
import SDWebImage
import CoreSpotlight
import ImgurKit
import Mixpanel
import UserNotifications

enum AppTabContent: String {
    case SubscriptionsNavigation = "subscriptions-navigation"
    case SearchNavigation = "search-navigation"
    case MessagesNavigation = "messages-navigation"
    case ProfileNavigation = "profile-navigation"
}

enum DelayedAppAction {
    case handleNotification(notification: UNNotification)
    case openViewController(viewController: UIViewController)
    case performBlock(block: (() -> Void))
}

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var galleryWindow: UIWindow?
    
    override init() {
        super.init()
        
        DataController.shared.authenticationController = self.authenticationController
        UserActivityController.shared.authenticationController = self.authenticationController
        self.managedObjectContext = DataController.shared.createMainContext()
    }
    
    let authenticationController = AuthenticationController(clientID: Config.redditClientID, redirectUri: Config.redditRedirectURL, clientName: Config.redditClientName)
    
    fileprivate weak var authenticationViewController: UIViewController?
    lazy var cherryController = { CherryController() }()
    lazy var productStoreController = { ProductStoreController() }()
    var displayModeController = DisplayModeController()
    let fontSizeController = FontSizeController()
    let passcodeController = PasscodeController()
    let userNotificationsHandler = UserNotificationsHandler()
    lazy var imageLoader: BeamImageLoader = {
        return BeamImageLoader()
    }()
    lazy var imgurController: ImgurController = {
        let controller = ImgurController()
        controller.clientID = Config.imgurClientID
        return controller
    }()
    
    //This is a workaround for a long standing bug since iOS 9, userInfo is removed from searchable items if there isn't a strong reference to them for some time.
    private var searchableUserActivities = [NSUserActivity]()
    
    var managedObjectContext: NSManagedObjectContext!
    
    var isRunningTestFlight: Bool {
        var isRunningTestflight = false
        if let receiptLastPathComponent = Bundle.main.appStoreReceiptURL?.lastPathComponent {
            isRunningTestflight = (receiptLastPathComponent == "sandboxReceipt")
        }
        return isRunningTestflight
    }
    
    /// The remote notifications device token
    var deviceToken: Data?
    /// If the device has registered for notifications
    private var hasRegisteredForRemoteNotifications: Bool = false
 
    private var messagesUpdateTimer: Timer?
    
    var isWindowUsable = false {
        didSet {
            if self.isWindowUsable {
                self.windowBecameUsable()
            }
        }
    }
    
    private var showPasscodeOnActive = true
    
    // MARK: - Lifecycle
    
    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //Register for background app refresh
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        //Setup application features
        self.setupStyle()
        
        //Clear expired content from the database
        self.clearExpiredContent()
        
        UserSettings.registerDefaults()
        
        if UserSettings[.firstLaunchDate] == nil {
            UserSettings[.firstLaunchDate] = Date()
        }
        
        self.cherryController.requestCherryFeatures()
        
        self.displayModeController.updateSettings()
        self.displayModeController.updateCurrentMode()
        
        let cacheConfig = SDImageCache.shared().config
        cacheConfig.shouldDecompressImages = false
        //Max cache size: 400MB
        cacheConfig.maxCacheSize = UInt(400 * 1000 * 1000)
        //Max cache age: 3 days
        cacheConfig.maxCacheAge = 60 * 60 * 60 * 24 * 3
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.contextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.cherryAccessTokenDidChange(_:)), name: .CherryAccessTokenDidChange, object: self.cherryController)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.userDidChange(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: self.authenticationController)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.messageDidChangeUnreadState(_:)), name: .RedditMessageDidChangeUnreadState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationWindowDidBecomeVisible(_:)), name: .UIWindowDidBecomeVisible, object: self.window)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.displayModeDidChangeNotification(_:)), name: .DisplayModeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.contentSizeCategoryDidChange(_:)), name: .UIContentSizeCategoryDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.userSettingDidChange(_:)), name: .SettingsDidChangeSetting, object: nil)
        
        if let launchOptions = launchOptions, let launchUrl = launchOptions[UIApplicationLaunchOptionsKey.url] as? URL {
            do {
                try openApplicationUrl(launchUrl)
            } catch {
                NSLog("\(error)")
            }
        }
        
        self.updateMessagesState()
        
        self.configureTabBarItems()
        
        self.configureAnalyticsServices()

        //Register for remote notifications
        self.registerForNotifications()
        if UserSettings[.hasBeenShownTheWelcomeScreen] {
            self.userNotificationsHandler.registerForUserNotifications()
        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        self.messagesUpdateTimer = Timer.scheduledTimer(timeInterval: 120, target: self, selector: #selector(AppDelegate.messageUpdateTimerDidFire(_:)), userInfo: nil, repeats: true)
        self.messagesUpdateTimer?.tolerance = 20
        
        self.handleAppOpenAction(launchOptions)
        
        self.showPasscodeOnActive = true
        
        Mixpanel.sharedInstance()?.joinExperiments {
            self.configureTabBarItems()
        }
        
        //Learn the device some reddit words, helping with spelling and auto correct
        self.learnRedditWords()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.passcodeController.applicationDidEnterBackground(application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.passcodeController.applicationWillEnterForeground(application)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if self.showPasscodeOnActive == true {
            self.passcodeController.presentPasscodeWindow()
            self.showPasscodeOnActive = false
        }
        Trekker.default.resume()
        if !UserSettings[.hasBeenShownTheWelcomeScreen] && !self.authenticationController.isAuthenticated {
            UserSettings[.hasBeenShownTheWelcomeScreen] = true
                self.tabBarController?.performSegue(withIdentifier: "showWelcome", sender: nil)
        }
        self.userDidChange(nil)
        
        self.updateFavoriteSubredditShortcuts()
        
        //Reset the badge count
        UserSettings[.notificationsBadgeCount] = 0
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        self.clearExpiredContent()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        do {
            try openApplicationUrl(url)
        } catch {
            return InternalLinkRoutingController.shared.routeURL(url)
        }
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        do {
            try openApplicationUrl(url)
        } catch {
            guard self.isWindowUsable else {
                //The window isn't usable yet, schedule the action to be performed later
                self.scheduleAppAction(DelayedAppAction.performBlock(block: {
                    _ = InternalLinkRoutingController.shared.routeURL(url)
                }))
                return true
            }
            return InternalLinkRoutingController.shared.routeURL(url)
        }
        return true
    }
    
    // MARK: - NSUserActivity
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == "com.madeawkward.beam.subreddit" {
            if let identifier = userActivity.userInfo?["id"] as? String {
                do {
                    if let subreddit = try Subreddit.fetchObjectWithIdentifier(identifier, context: self.managedObjectContext) as? Subreddit {
                        
                        //Open the subreddit
                        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
                        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
                            tabBarController.subreddit = subreddit
                            if self.isWindowUsable {
                                AppDelegate.topViewController()?.present(tabBarController, animated: true, completion: nil)
                            } else {
                                self.scheduleAppAction(DelayedAppAction.openViewController(viewController: tabBarController))
                            }
                        }
                        return true
                    }
                } catch {
                    //Let is fall through
                    NSLog("Failed to fetch subreddit with identifier \(identifier) for hand-off")
                }
            }
            if let webPageURL = userActivity.webpageURL {
                var components = URLComponents(url: webPageURL, resolvingAgainstBaseURL: false)
                components?.scheme = Config.internalURLScheme
                if let subredditURL = components?.url {
                    guard self.isWindowUsable else {
                        //The window isn't usable yet, schedule the action to be performed later
                        self.scheduleAppAction(DelayedAppAction.performBlock(block: {
                            _ = InternalLinkRoutingController.shared.routeURL(subredditURL)
                        }))
                        return true
                    }
                    return InternalLinkRoutingController.shared.routeURL(subredditURL)
                }
            }
            return false
        }
        if userActivity.activityType == CSSearchableItemActionType {
            if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                print("Unique identifer \(uniqueIdentifier)")
                do {
                    if let subreddit = try Subreddit.fetchObjectWithIdentifier(uniqueIdentifier, context: self.managedObjectContext) as? Subreddit {
                        //Open the subreddit
                        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
                        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
                            tabBarController.subreddit = subreddit
                            if self.isWindowUsable {
                                AppDelegate.topViewController()?.present(tabBarController, animated: true, completion: nil)
                            } else {
                                self.scheduleAppAction(DelayedAppAction.openViewController(viewController: tabBarController))
                            }
                        }
                        return true
                    }
                } catch {
                    //Let it fall through
                    NSLog("Failed to fetch subreddit with identifier \(uniqueIdentifier) for spotlight search")
                }
                if let webPageURL = userActivity.webpageURL {
                    var components = URLComponents(url: webPageURL, resolvingAgainstBaseURL: false)
                    components?.scheme = Config.internalURLScheme
                    if let subredditURL = components?.url {
                        guard self.isWindowUsable else {
                            //The window isn't usable yet, schedule the action to be performed later
                            self.scheduleAppAction(DelayedAppAction.performBlock(block: {
                                _ = InternalLinkRoutingController.shared.routeURL(subredditURL)
                            }))
                            return true
                        }
                        return InternalLinkRoutingController.shared.routeURL(subredditURL)
                    }
                }
            }
            return false
        }
        return false
    }
    
    func updateSearchableSubreddits() {
        guard !UserSettings[.privacyModeEnabled] else {
            return
        }
        let objectContext: NSManagedObjectContext! = DataController.shared.privateContext
        let fetchRequest = NSFetchRequest<Subreddit>(entityName: Subreddit.entityName())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastVisitDate", ascending: false), NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "identifier", ascending: true)]
        fetchRequest.fetchLimit = 200
        objectContext.perform {
            do {
                var subreddits = try objectContext.fetch(fetchRequest)
                subreddits.append(try Subreddit.frontpageSubreddit())
                subreddits.append(try Subreddit.allSubreddit())
                
                let searchableItems = subreddits.compactMap({ (subreddit) -> CSSearchableItem? in
                    return subreddit.createSearchableItem()
                })
                CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
            } catch {
                NSLog("Error getting subreddits for search indexing \(error)")
            }
        }
        
    }
    
    // MARK: - Words
    
    private func learnRedditWords() {
        UITextChecker.learnWord("subreddit")
        UITextChecker.learnWord("subreddits")
        UITextChecker.learnWord("nsfw")
        UITextChecker.learnWord("reddit")
        UITextChecker.learnWord("gilder")
        UITextChecker.learnWord("gilded")
        UITextChecker.learnWord("snoo")
        UITextChecker.learnWord("nsfl")
        UITextChecker.learnWord("imgur")
        UITextChecker.learnWord("askreddit")
        UITextChecker.learnWord("pcmasterrace")
        UITextChecker.learnWord("gilding")
        UITextChecker.learnWord("multireddit")
        UITextChecker.learnWord("multireddits")
        UITextChecker.learnWord("upvote")
        UITextChecker.learnWord("downvote")
    }
    
    // MARK: - UIApplicationShortCuts
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        case "com.madeawkward.beam.shortcut.subreddit":
            if let displayName = shortcutItem.userInfo?["display_name"] as? String, let identifier = shortcutItem.userInfo?["identifier"] as? String, let URL = URL(string: "\(Config.internalURLScheme)://r/\(displayName)") {
                do {
                    if let subreddit = try Subreddit.fetchObjectWithIdentifier(identifier, context: self.managedObjectContext) as? Subreddit {
                        //Open the subreddit
                        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
                        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
                            tabBarController.subreddit = subreddit
                            if self.isWindowUsable {
                                AppDelegate.topViewController()?.present(tabBarController, animated: true, completion: nil)
                            } else {
                                self.scheduleAppAction(DelayedAppAction.openViewController(viewController: tabBarController))
                            }
                        }
                    } else {
                        guard self.isWindowUsable else {
                            self.scheduleAppAction(DelayedAppAction.performBlock(block: {
                                _ = InternalLinkRoutingController.shared.routeURL(URL)
                            }))
                            return
                        }
                        _ = InternalLinkRoutingController.shared.routeURL(URL)
                    }
                } catch {
                    guard self.isWindowUsable else {
                        self.scheduleAppAction(DelayedAppAction.performBlock(block: {
                            _ = InternalLinkRoutingController.shared.routeURL(URL)
                        }))
                        return
                    }
                    _ = InternalLinkRoutingController.shared.routeURL(URL)
                }
                
                completionHandler(true)
                return
            }
        default:
            AWKDebugLog("App can't handle shortcut: \(shortcutItem.type)")
            
        }
        
        completionHandler(false)
    }
    
    func updateFavoriteSubredditShortcuts() {
        //Update the 3D Touch shortcuts
        do {
            if let subreddits = try self.favoriteSubreddits(), subreddits.count > 0 {
                let shortcutItems = subreddits[0..<min(subreddits.count, 4)].compactMap { (subreddit) -> UIApplicationShortcutItem? in
                    return subreddit.createApplicationShortcutItem()
                }
                UIApplication.shared.shortcutItems = shortcutItems.reversed()
            }
            
        } catch {
            AWKDebugLog("Failed to get bookmarked subredits")
        }
    }
    
    private func favoriteSubreddits() throws -> [Subreddit]? {
        let objectContext: NSManagedObjectContext! = DataController.shared.privateContext
        var subreddits: [Subreddit]!
        var thrownError: Error?
        objectContext.performAndWait {
            do {
                let fetchRequest = NSFetchRequest<Subreddit>(entityName: Subreddit.entityName())
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true), NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "identifier", ascending: true)]
                fetchRequest.predicate = NSPredicate(format: "isBookmarked == YES && NOT (identifier IN %@)", [Subreddit.frontpageIdentifier, Subreddit.allIdentifier])
                fetchRequest.fetchLimit = 3
                subreddits = try objectContext.fetch(fetchRequest)
                let frontpage = try Subreddit.frontpageSubreddit()
                subreddits.insert(frontpage, at: 0)
            } catch {
                thrownError = error
            }
        }
        if let thrownError = thrownError {
            throw thrownError
        }
       
        return subreddits
    }
    
    // MARK: - App Open Action
    
    func handleAppOpenAction(_ launchOptions: [AnyHashable: Any]?) {
        let appOpenOption = UserSettings[.appOpen]
        let appOpenView = appOpenOption.view
        switch appOpenView {
        case AppLaunchView.Subreddits, AppLaunchView.Multireddits:
            self.changeActiveTabContent(AppTabContent.SubscriptionsNavigation)
            UserSettings[.subscriptionsListType] = appOpenView.rawValue
        case AppLaunchView.Messages:
            self.changeActiveTabContent(AppTabContent.MessagesNavigation)
        case AppLaunchView.Profile:
            self.changeActiveTabContent(AppTabContent.ProfileNavigation)
        case AppLaunchView.Frontpage, AppLaunchView.All, AppLaunchView.LastVisitedSubreddit:
            self.changeActiveTabContent(AppTabContent.SubscriptionsNavigation)
            var subreddit: Subreddit?
            do {
                if appOpenView == AppLaunchView.Frontpage {
                    subreddit = try Subreddit.frontpageSubreddit()
                } else if appOpenView == AppLaunchView.All {
                    subreddit = try Subreddit.allSubreddit()
                } else if appOpenView == AppLaunchView.LastVisitedSubreddit {
                    subreddit = RedditActivityController.recentlyVisitedSubreddits.first
                }
            } catch {
                
            }
            if let subreddit = subreddit {
                //Open the subreddit
                let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
                if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
                    tabBarController.subreddit = subreddit
                    self.scheduleAppAction(DelayedAppAction.openViewController(viewController: tabBarController))
                }
            }

        }
    }
    
    // MARK: - Background App Refresh
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard self.authenticationController.userSessionAvailable else {
            completionHandler(UIBackgroundFetchResult.noData)
            exit(0)
        }
        guard UserSettings[.redditMessageNotificationsEnabled] && self.authenticationController.isAuthenticated == true else {
            completionHandler(UIBackgroundFetchResult.noData)
            exit(0)
        }
        MessageCollectionQuery.fetchUnreadMessages { (messages, _) -> Void in
            guard let messages = messages else {
                completionHandler(UIBackgroundFetchResult.failed)
                return
            }
            let filteredMessages = self.unnotifiedMessages(messages)
            var badgeCount = UserSettings[.notificationsBadgeCount]
            filteredMessages.forEach({ (message) in
                badgeCount += 1
                
                let content = message.notificationContent()
                content.badge = NSNumber(value: badgeCount)
                let request = UNNotificationRequest(identifier: message.objectName ?? UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            })
            if filteredMessages.count > 0 {
                completionHandler(UIBackgroundFetchResult.newData)
            } else {
                completionHandler(UIBackgroundFetchResult.noData)
            }
            UserSettings[.notificationsBadgeCount] = badgeCount
        }
    }
    
    private func unnotifiedMessages(_ messages: [Message]) -> [Message] {
        var existingMessageNotificationIdentifiers = [String]()
        if let messageIdentifiers = UserSettings[.notifiedMessages] {
            existingMessageNotificationIdentifiers.append(contentsOf: messageIdentifiers)
        }
        let filteredMessages = messages.filter { (message) -> Bool in
            guard let objectName = message.objectName, existingMessageNotificationIdentifiers.contains(objectName) != true  else {
                return false
            }
            return true
        }
        existingMessageNotificationIdentifiers.append(contentsOf: messages.filter({ $0.objectName != nil }).map({ return $0.objectName! }))
        UserSettings[.notifiedMessages] = existingMessageNotificationIdentifiers
        return filteredMessages
    }
    
    // MARK: - Analytics
    
    private func configureAnalyticsServices() {
        Trekker.default.configure(with: Config.createAnalyticsServices())
    
        self.updateAnalyticsUser()
    }
    
    func updateAnalyticsUser(_ notification: Notification? = nil) {
        DispatchQueue.main.async { () -> Void in
            
            if self.isRunningTestFlight {
                AWKDebugLog("App is running from TestFlight, updating analytics accordingly")
            }
            //Check for a previous token, if it doesn't not exist generate a new one
            var userToken = UserSettings[.analyticsProfileToken]
            if userToken == nil {
                let token = UUID().uuidString
                UserSettings[.analyticsProfileToken] = token
                userToken = token
            }
            let profile = TrekkerUserProfile(identifier: userToken, firstname: nil, lastname: nil, fullName: userToken)
            
            var notificationSettings = [String]()
            if UserSettings[.shopNotificationsEnabled] {
                notificationSettings.append("shop")
            }
            if UserSettings[.announcementNotificationsEnabled] {
                notificationSettings.append("announcements")
            }
            if UserSettings[.redditMessageNotificationsEnabled] {
                notificationSettings.append("messages")
            }
            
            var properties: [String: Any] = ["Is logged in": self.authenticationController.isAuthenticated, "Using TestFlight": self.isRunningTestFlight, "Notification settings": notificationSettings]
            properties["Thumbnail view type"] = UserSettings[.thumbnailsViewType].rawValue
            properties["Auto darkmode on"] = UserSettings[.nightModeAutomaticEnabled]
            properties["Darkmode on"] = UserSettings[.nightModeEnabled]
            properties["In app sounds on"] = UserSettings[.playSounds]
            properties["General privacy overlay on"] = UserSettings[.showPrivacyOverlay]
            properties["General spoiler overlay on"] = UserSettings[.showSpoilerOverlay]
            properties["Open app on"] = UserSettings[.appOpen].view.rawValue
            properties["Open links in"] = UserSettings[.browser].displayName
            properties["Show metadata on"] = UserSettings[.showPostMetadata]
            properties["Show metadata date on"] = UserSettings[.showPostMetadataDate]
            properties["Show metadata domain on"] = UserSettings[.showPostMetadataDomain]
            properties["Show metadata gilded on"] = UserSettings[.showPostMetadataGilded]
            properties["Show metadata locked on"] = UserSettings[.showPostMetadataLocked]
            properties["Show metadata stickied on"] = UserSettings[.showPostMetadataStickied]
            properties["Show metadata username on"] = UserSettings[.showPostMetadataUsername]
            properties["Show metadata subreddit on"] = UserSettings[.showPostMetadataSubreddit]
            properties["Stealth mode enabled"] = UserSettings[.privacyModeEnabled]
            profile.customProperties = properties
            Trekker.default.identify(using: profile)
            
            //Also use the user properties as event super properties
            Trekker.default.registerEventSuperProperties(properties)
        }
    }
    
    // MARK: - Data changes
    
    @objc private func contextDidSave(_ notification: Notification) {
        let context = notification.object as! NSManagedObjectContext
        if context == managedObjectContext.parent {
            managedObjectContext.perform({ () -> Void in
                NSFetchedResultsController<NSManagedObject>.deleteCache(withName: nil)
                self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
            })
        }
    }
    
    @objc private func cherryAccessTokenDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            guard let token = self.cherryController.accessToken, let deviceToken = self.deviceToken else {
                return
            }
            if !self.hasRegisteredForRemoteNotifications {
                self.registerDevice(token, deviceToken: deviceToken)
            }
                
        }
    }

    @objc private func userDidChange(_ notification: Notification?) {
        DispatchQueue.main.async { () -> Void in
            if (notification as NSNotification?)?.userInfo?["error"] is NSError {
                let alertController = BeamAlertController(title: AWKLocalizedString("logged-out-problem"), message: "logged-out-problem-message", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addCloseAction()
                AppDelegate.topViewController()?.present(alertController, animated: true, completion: nil)
            }
            self.updateAnalyticsUser()
            self.updateMessagesState()
            self.configureTabBarItems()
        }
    }
    
    // MARK: - Notifications
    
    @objc private func applicationWindowDidBecomeVisible(_ notification: Notification?) {
        DispatchQueue.main.async { () -> Void in
            self.isWindowUsable = true
        }
    }
    
    @objc private func messageDidChangeUnreadState(_ notification: Notification?) {
        DispatchQueue.main.async {
            self.updateMessagesState()
        }
    }
    
    /// The action to take if the window wasn't usable on app open, due to passcode or something else. See `scheduleAppAction(:)`
    private var scheduledAppAction: DelayedAppAction?
    
    /**
     Schedule a delayed app action, this action is performed as soon as it is able to perform this action.
     This could be after the window becomes available (the window is not directly available at launch), or after the app has been unlocked when protected with a passcode
    
     - Parameter action: The action to perform after the delay is over
     */
    func scheduleAppAction(_ action: DelayedAppAction) {
        if self.scheduledAppAction != nil {
            //Notifications can always replace the delayed action
            switch action {
            case .handleNotification:
                self.scheduledAppAction = action
            default:
                print("Delayed action already set \(String(describing: self.scheduledAppAction))")
            }
        } else {
             self.scheduledAppAction = action
        }
    }
    
    private func windowBecameUsable() {
        guard self.isWindowUsable else {
            return
        }
        guard self.passcodeController.unlocked == true else {
            return
        }
        if let scheduledAppAction = self.scheduledAppAction {
            switch scheduledAppAction {
            case .handleNotification(let notification):
                self.userNotificationsHandler.handleNotification(notification)
            case .openViewController(let viewController):
               AppDelegate.topViewController()?.present(viewController, animated: true, completion: nil)
            case .performBlock(let block):
                block()
            }
            self.scheduledAppAction = nil
        }
    }
    
    @objc private func messageUpdateTimerDidFire(_ timer: Timer) {
        self.updateMessagesState()
    }
    
    func updateMessagesState() {
        self.configureTabBarItems()
        
        if self.authenticationController.isAuthenticated {
            self.authenticationController.requestActiveUser({ (_, _, _) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.configureTabBarItems()
                })
            })
        }
    }
    
    private func clearExpiredContent() {
        let clearOperation = DataController.clearExpiredContentOperation()
        DataController.shared.executeAndSaveOperations([clearOperation], handler: nil)
    }
    
    // MARK: - Authentication
    
    func presentAuthenticationViewController() {
        guard let url = self.authenticationController.authorizationURL else {
            return
        }
        //Also use Safari on the simulator because SFSafariViewController is sometimes broken on the simulator
        let safariViewController = BeamSafariViewController(url: url)
        safariViewController.delegate = self
        self.authenticationViewController = safariViewController
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 9 && ProcessInfo.processInfo.operatingSystemVersion.minorVersion >= 2 {
            let navigationController = UINavigationController(rootViewController: safariViewController)
            navigationController.setNavigationBarHidden(true, animated: false)
            AppDelegate.topViewController()?.present(navigationController, animated: true, completion: nil)
        } else {
            AppDelegate.topViewController()?.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    func presentAccountSwitcher(sender: UIView) {
        let sessions = AppDelegate.shared.authenticationController.fetchAllAuthenticationSessions()
        if sessions.count < 2 {
            return
        }
        
        let alertController = BeamAlertController(title: AWKLocalizedString("switch-account-title"), message: AWKLocalizedString("switch-account-message"), preferredStyle: UIAlertControllerStyle.actionSheet)
        
        for session in sessions {
            let action = UIAlertAction(title: session.username ?? "Unknown", style: .default, handler: { (_) -> Void in
                self.switchToSession(session)
            })
            alertController.addAction(action)
        }
        
        alertController.addCancelAction()
        
        alertController.popoverPresentationController?.sourceView = sender.superview
        alertController.popoverPresentationController?.sourceRect = sender.frame
        
        AppDelegate.topViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    private func switchToSession(_ session: AuthenticationSession?) {
        AppDelegate.shared.authenticationController.switchToAuthenticationSession(session) { (error) in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    let message = AWKLocalizedString("switching-account-error-title").replacingLocalizablePlaceholders(for: ["ERRORCODE": "\(error.code)"])
                    let alertController = BeamAlertController(alertWithCloseButtonAndTitle: AWKLocalizedString("switching-account-error-title"), message: message)
                    AppDelegate.topViewController()?.present(alertController, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    // MARK: - URL schemes
    
    func openApplicationUrl(_ url: URL) throws {
        let path = url.path
        if url.scheme == "beam" && path == "/authorized" {
            self.authenticationController.authenticateURL(url, handler: { (loggedIn: Bool, error: Error?) -> Void in
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    self.authenticationViewController?.dismiss(animated: UIApplication.shared.applicationState == .active, completion: { () -> Void in
                        self.authenticationViewController = nil
                        
                        if !loggedIn {
                            var title = AWKLocalizedString("login-failed")
                            var message = AWKLocalizedString("login-retry")
                            if let error = error as NSError?, error.domain == SnooErrorDomain && error.code == 409 {
                                title = AWKLocalizedString("account-already-exists")
                                message = AWKLocalizedString("account-already-exists-message")
                            }
                            AppDelegate.topViewController()?.present(BeamAlertController(alertWithCloseButtonAndTitle: title, message: message), animated: true, completion: nil)
                            
                        }
                    })
                    
                    if !loggedIn {
                        NSLog("Did call authentication URL, but not logged in. Error: \(String(describing: error))")
                    }
                    
                })
            })
        } else {
            throw NSError.beamError(localizedDescription: "Could not open application URL")
        }
    }
    
    func openExternalURLWithCurrentBrowser(_ url: URL) -> UIViewController? {
        if url.isYouTubeURL {
            return UserSettings[.youTubeApp].handleURL(url)
        } else {
            return UserSettings[.browser].handleURL(url)
        }
    }
    
    // MARK: - (Push) Notifications
    
    /**
    Supported categories:
    - `reddit_message`. Actions: reply
    */
    
    private func registerForNotifications() {
        //Register to get a device token
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        let nsError = error as NSError
        guard nsError.code != 3010 else {
            return
        }
        AWKDebugLog("Failed to register for remote notifications \(error)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.deviceToken = deviceToken
        if let token = AppDelegate.shared.cherryController.accessToken {
            self.registerDevice(token, deviceToken: deviceToken)
        }
        Trekker.default.registerForPushNotifications(deviceToken)
    }
    
    private func registerDevice(_ cherryToken: String, deviceToken: Data) {
        let appRelease = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        
        #if DEBUG
            let usingSandbox = true
        #else
            let usingSandbox = false
        #endif
        
        let registrationOptions = RemoteNotificationsRegistrationOptions(appRelease: appRelease, appVersion: appVersion, sandboxed: usingSandbox, userNotificationsEnabled: true)
        let task = RemoteNotificationsRegistrationTask(token: cherryToken, deviceToken: deviceToken, registrationOptions: registrationOptions)
        task.start({ (result: TaskResult) -> Void in
            DispatchQueue.main.async { () -> Void in
                if let error = result.error {
                    AWKDebugLog("Cherry remote notification registration failed: \(error)")
                } else {
                    self.hasRegisteredForRemoteNotifications = true
                    AWKDebugLog("Registered device with result %@ token %@", result, deviceToken.description)
                }
            }
        })
    }
    
    // MARK: - Appearance
    
    var tabBarController: UITabBarController? {
        return self.window?.rootViewController as? UITabBarController
    }
    
    func changeActiveTabContent(_ newContent: AppTabContent) {
        if let viewController = self.tabBarController?.viewControllers?.first(where: { (viewController) -> Bool in
            return viewController.restorationIdentifier == newContent.rawValue
        }) {
            self.tabBarController?.selectedViewController = viewController
        }
    }
    
    func viewControllerForAppTabContent(_ content: AppTabContent) -> UIViewController? {
        if let viewController = self.tabBarController?.viewControllers?.first(where: { (viewController) -> Bool in
            return viewController.restorationIdentifier == content.rawValue
        }) {
            return viewController
        }
        return nil
    }
    
    @objc private func displayModeDidChangeNotification(_ notification: Notification) {
        self.configureTabBarItems()
        self.setupStyle()
    }
    
    private func configureTabBarItems() {
        
        let subscriptionsNavigation: UIViewController = self.viewControllerForAppTabContent(AppTabContent.SubscriptionsNavigation)!
        let messagesNavigation: UIViewController = self.viewControllerForAppTabContent(AppTabContent.MessagesNavigation)!
        let searchNavigation: UIViewController? = self.viewControllerForAppTabContent(AppTabContent.SearchNavigation)
        let profileNavigation: UIViewController = self.viewControllerForAppTabContent(AppTabContent.ProfileNavigation)!
        
        searchNavigation?.tabBarItem.title = AWKLocalizedString("search-title")
        profileNavigation.tabBarItem.title = AWKLocalizedString("profile-title")
        
        //The tabBarItem for home needs special treatment for the title, the other items are configure in Main.Storyboard
            if self.authenticationController.isAuthenticated {
                subscriptionsNavigation.tabBarItem.title = AWKLocalizedString("subscriptions-title")
            } else {
                subscriptionsNavigation.tabBarItem.title = AWKLocalizedString("subreddits-title")
            }

        //The tabBarItem for messages needs special treatment. The other items are configured in Main.storyboard
        let currentUser = self.authenticationController.activeUser(self.managedObjectContext)
        var image = UIImage(named: "tabbar_inbox")
        var selectedImage: UIImage? = nil
        if currentUser?.hasMail == true && self.authenticationController.isAuthenticated {
            var extraString = ""
            if self.displayModeController.currentMode == DisplayMode.dark {
                extraString = "_dark"
            }
            image = UIImage(named: "tabbar_inbox\(extraString)_badge")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
            selectedImage = UIImage(named: "tabbar_inbox\(extraString)_badge_selected")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        }
        let tabBarItem = UITabBarItem(title: AWKLocalizedString("messages-title"), image: image, selectedImage: selectedImage)
        tabBarItem.imageInsets = UIEdgeInsets(top: -2, left: 0, bottom: 2, right: 0)
        messagesNavigation.tabBarItem = tabBarItem
    }
    
    /*
    This method has to be overwritten in order to make the AWKGalleryViewController support landscape, but keep the rest of the app in portrait.
    AWKGalleryViewController is presented modally so you have to find it on the "presentedViewController" property somewhere in the viewcontrollers hierachy.
    This method will be called everytime a new viewController is added somewhere in the hierachy.The project orientation settings should still be set to support landscape.
    */
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            return .all
        }
        if AppDelegate.topViewController() is SFSafariViewController {
            return .allButUpsideDown
        }
        if window == self.galleryWindow {
            return .allButUpsideDown
        }
        if window == self.passcodeController.passcodeWindow {
            return .portrait
        }
        return .portrait
    }
    
    /// Finds the topmost view controller on the specified view controller. If you don't specify a view controller where to look on, the window's root view controller will be used.
    class func topViewController(_ viewController: UIViewController? = nil) -> UIViewController? {
        
        guard viewController != nil else {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                return topViewController(rootViewController)
            }
            return nil
        }
        
        if viewController?.presentedViewController == nil {
            return viewController
        }
        
        //If the presentedViewController of the viewController is a UINavigationController we need to use the topViewController of that one.
        if let navigationController = viewController?.presentedViewController as? UINavigationController, let topViewController = navigationController.topViewController {
            if let topPresentedViewController = topViewController.presentedViewController {
                return AppDelegate.topViewController(topPresentedViewController)
            } else {
                return AppDelegate.topViewController(topViewController)
            }
        }
        
        if let presentedViewController = viewController?.presentedViewController {
            return AppDelegate.topViewController(presentedViewController)
        } else {
            return viewController
        }
    }
    
    private func setupStyle() {
        let tintColor = DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        if self.window?.tintColor != tintColor {
            self.window?.tintColor = tintColor
        }
        
        //Set the tintColor of buttons in UIActivityViewController
        UIView.appearance(whenContainedInInstancesOf: [UIActivityViewController.self]).tintColor = UIColor.beamColor()
    }
    
    @objc func contentSizeCategoryDidChange(_ notification: Notification) {
        //This method is called when the font size changes in the phone settings. Use this to clear any caches related to this
    }
    
    @objc func userSettingDidChange(_ notification: Notification) {
        //This method is called when a setting changes, the object will be the key of the setting.
    }
    
}

extension AppDelegate: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if controller.presentingViewController != nil {
            controller.dismiss(animated: true) { () -> Void in
                self.authenticationViewController = nil
            }
        }
    }
}
