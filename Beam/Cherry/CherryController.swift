//
//  CherryController.swift
//  beam
//
//  Created by Robin Speijer on 17-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CherryKit
import CoreData

struct CherryFeatures {
    var imageURLPatterns: [String] = ["^https?://i.imgur.com/", "^https?://i.reddituploads.com/", "^https?://(?: www.)?gfycat.com/", "(.jpe?g|.png|.gif)$"]
    
    /// The search keywords that are blocked. If the search term (the complete string) contains any of these words it's blocked from search, unless it's in the whitelist.
    /// This list is loaded from features.json upon reload, but also has some keywords below in case the features.json fails
    var blockedSearchKeywords: [String] = ["nude", "gonewild", "porn", "boob", "naked", "dick", "penis", "vagina", "ass", "butt", "pussy", "tit", "fuck", "nsfw"]
    
    /// The full search terms (so multiple keywords) that are allowed when one of the keywords is blocked in `blockedSearchKeywords`.
    /// Example: `fuck` is blocked, but if `interestingasfuck` is in this list, `interestingasfuck` is no longer blocked, but `fucking`, `fucked` or `fuck you` still are
    /// This list is loaded from features.json upon reload, but also has some terms below in case the features.json fails
    var whitelistedSearchTerms: [String] = ["earthporn", "spaceporn", "mindfuck", "interestingasfuck", "foodporn", "geekporn"]
    
    /// The usernames of admin users
    var adminUsers: [String]?
    
    // The data behind the notifications that appear in the subscription list.
    var bannerNotifications: [BannerNotification]?
    
    init(JSON: NSDictionary) {
        if let regexes = JSON["image_url_regexes"] as? [String] {
            self.imageURLPatterns = regexes
        }
        if let blockedSearchKeywords = JSON["blocked_search_keywords"] as? [String] {
            self.blockedSearchKeywords = blockedSearchKeywords
        }
        if let whitelistedSearchTerms = JSON["whitelisted_search_terms"] as? [String] {
            self.whitelistedSearchTerms = whitelistedSearchTerms
        }
        self.adminUsers = JSON["admin_users"] as? [String]
    }
    
    init() {
        
    }
}

extension Notification.Name {
    
    public static let CherryFeaturesDidChange = Notification.Name(rawValue: "cherry-features-did-change")
    public static let CherryAccessTokenDidChange = Notification.Name(rawValue: "cherry-token-did-change")
    
}

final class CherryController: NSObject {
    
    var accessToken: String? {
        didSet {
            NotificationCenter.default.post(name: .CherryAccessTokenDidChange, object: self)
            do {
                guard let data = self.accessToken?.data(using: String.Encoding.utf8) else {
                    return
                }
                try Keychain.save("cherry-access-token", data: data)
            } catch {
                //We don't care about the error
            }
            
        }
    }
    var features: CherryFeatures?

    override init() {
        super.init()
        
        self.loadFeatures()
        
        do {
            if let data = try Keychain.load("cherry-access-token"), let accessToken: String = String(data: data, encoding: String.Encoding.utf8) {
                self.accessToken = accessToken
            }
        } catch {
            //We don't care about the error
        }
        
        self.configureCherry()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func configureCherry() {
        guard !Config.CherryAppVersionKey.isEmpty else {
            NSLog("The app is missing the Cherry App Version key, signatures won't be generated and some features (including inline images) won't work.")
            return
        }
        Cherry.appVersion = Config.cherryAppVersion
        Cherry.signatureForRequest = { (request: URLRequest) -> String? in
            if let bodyData = request.httpBody, let body = String(data: bodyData, encoding: .utf8) {
                var shaResult = body.hmac(.sha256, key: Config.CherryAppVersionKey)
                shaResult = shaResult.replacingOccurrences(of: " ", with: "")
                shaResult = shaResult.replacingOccurrences(of: "<", with: "")
                shaResult = shaResult.replacingOccurrences(of: ">", with: "")
                return shaResult
            } else {
                return nil
            }
        }
    }
    
    func prepareAuthorization() {
        guard !Config.CherryAppVersionKey.isEmpty else {
            return
        }
        let cherryAuthRequest = CherryKit.AuthorizationTask()
        cherryAuthRequest.start { (result: CherryKit.TaskResult) -> Void in
            if let result = result as? CherryKit.AuthorizationTaskResult {
                self.accessToken = result.accessToken
                NSLog("Cherry Access Token: %@", result.accessToken)
            } else if let error = result.error {
                NSLog("Could not get cherry access token: \(error)")
            }
        }
    }
    
    func requestCherryFeatures() {
        let featuresOperation = self.requestFeaturesOperation()
        DataController.shared.executeOperations([featuresOperation]) { [weak self] (error: Error?) -> Void in
            if let error = error {
                NSLog("Could not get cherry features: \(error)")
            } else {
                self?.prepareAuthorization()
            }
        }
    }
    
    func requestFeaturesOperation() -> DataRequest {
        var urlString = "http://files.beamreddit.com/features.json"
        if let language = Bundle.main.preferredLocalizations.first, let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            urlString = "http://files.beamreddit.com/features.json?lang=\(language)&build=\(build)"
        }
        guard let url = URL(string: urlString) else {
            fatalError("Unparseable cherry features URL string")
        }
        let request = DataRequest()
        request.queuePriority = .high
        request.urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.urlSession = AppDelegate.shared.authenticationController.userURLSession
        request.completionBlock = { () -> Void in
            if let result = request.result {
                let newFeatures = CherryFeatures(JSON: result)
                self.features = newFeatures
                self.saveFeatures()
                NotificationCenter.default.post(name: .CherryFeaturesDidChange, object: self)
                
            }
        }
        
        return request
    }

    var isAdminUser: Bool {
        let context: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
        var username: String?
        context?.performAndWait {
            username = AppDelegate.shared.authenticationController.activeUser(context)?.username
        }
        if let username = username, self.features?.adminUsers?.contains(username) == true {
            return true
        }
    
        let hasAdminAccount = AppDelegate.shared.authenticationController.fetchAllAuthenticationSessions().compactMap({ (session) -> String? in
            return session.username
        }).contains { (username) -> Bool in
            return self.features?.adminUsers?.contains(username) == true
        }
        return hasAdminAccount
    }
    
    func searchTermAllowed(term: String?) -> Bool {
        guard !AppDelegate.shared.authenticationController.userCanViewNSFWContent,
            let features = AppDelegate.shared.cherryController.features,
            let term = term?.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            term.count > 0 else {
            return true
        }
        
        var keywordBlocked = features.blockedSearchKeywords.contains { (keyword) -> Bool in
            return term.contains(keyword)
        }
        
        if keywordBlocked && features.whitelistedSearchTerms.contains(term) {
            keywordBlocked = false
        }
        
        return !keywordBlocked
    }
    
    fileprivate func saveFeatures() {
        if let adminUsers = self.features?.adminUsers {
            UserSettings[.cherryAdminUsers] = adminUsers
        }
        
        if let patterns = self.features?.imageURLPatterns {
            UserSettings[.cherryImageURLPatterns] = patterns
        }
        
    }
    
    fileprivate func loadFeatures() {
        var features = CherryFeatures()
        
        features.imageURLPatterns = UserSettings[.cherryImageURLPatterns]
        
        if let adminUsers = UserSettings[.cherryAdminUsers] {
            features.adminUsers = adminUsers
        }
        self.features = features
    }
    
}
