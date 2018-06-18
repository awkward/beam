//
//  Subreddit+Settings.swift
//  beam
//
//  Created by Rens Verhoeven on 16-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Snoo

extension Notification.Name {
    
    static let SubredditNSFWOverlaySettingDidChange = Notification.Name(rawValue: "SubredditNSFWOverlaySettingDidChange")
    static let SubredditSpoilerOverlaySettingDidChange = Notification.Name(rawValue: "SubredditSpoilerOverlaySettingDidChange")
    
}

extension Subreddit {
    
    fileprivate func overlayIdentifier() -> String? {
        if let permalink = self.permalink {
            return permalink
        } else if let identifier = self.identifier {
            return identifier
        }
        return nil
    }
    
    // MARK: - NSFW Overlay
    
    func setShowNSFWOverlay(_ show: Bool) {
        guard let overlayIdentifier = self.overlayIdentifier() else {
            return
        }
        var subredditLinks = [String: NSNumber]()
        if let subreddits = UserSettings[.subredditsPrivacyOverlaySetting] {
            subredditLinks = subreddits
        }
        subredditLinks[overlayIdentifier] = NSNumber(value: show)
        UserSettings[.subredditsPrivacyOverlaySetting] = subredditLinks
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .SubredditNSFWOverlaySettingDidChange, object: self)
        }
    }
    
    func shouldShowNSFWOverlay() -> Bool {
        guard let overlayIdentifier = self.overlayIdentifier() else {
            return UserSettings[.showPrivacyOverlay]
        }
        
        guard AppDelegate.shared.authenticationController.userCanViewNSFWContent else {
            return true
        }
        if let subreddits = UserSettings[.subredditsPrivacyOverlaySetting] {
            return subreddits[overlayIdentifier]?.boolValue ?? true
        }
        return UserSettings[.showPrivacyOverlay]
    }
    
    // MARK: - Spoiler Overlay
    
    func setShowSpoilerOverlay(_ show: Bool) {
        guard let overlayIdentifier = self.overlayIdentifier() else {
            return
        }
        var subredditLinks: Dictionary = [String: NSNumber]()
        if let subreddits = UserSettings[.subredditsSpoilerOverlaySetting] {
            subredditLinks = subreddits
        }
        subredditLinks[overlayIdentifier] = NSNumber(value: show)
        UserSettings[.subredditsSpoilerOverlaySetting] = subredditLinks
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .SubredditSpoilerOverlaySettingDidChange, object: self)
        }
        
    }
    
    func shouldShowSpoilerOverlay() -> Bool {
        guard let overlayIdentifier = self.overlayIdentifier() else {
            return true
        }
        if !UserSettings[.showSpoilerOverlay] {
            return false
        }
        if let subreddits = UserSettings[.subredditsSpoilerOverlaySetting] {
            return subreddits[overlayIdentifier]?.boolValue ?? true
        }
        return UserSettings[.showSpoilerOverlay]
    }
    
    var thumbnailViewType: ThumbnailsViewType? {
        get {
            guard let overlayIdentifier = self.overlayIdentifier() else {
                return nil
            }
            var thumbnailViewTypes = [String: String]()
            if let thumbnailViewSettings = UserSettings[.subredditsThumbnailSetting] {
                thumbnailViewTypes = thumbnailViewSettings
            }
            if let string = thumbnailViewTypes[overlayIdentifier], let viewType = ThumbnailsViewType(rawValue: string) {
                return viewType
            }
            return nil
        }
        set {
            guard let overlayIdentifier = self.overlayIdentifier() else {
                return
            }
            var thumbnailViewTypes = [String: String]()
            if let thumbnailViewSettings = UserSettings[.subredditsThumbnailSetting] {
                thumbnailViewTypes = thumbnailViewSettings
            }
            if newValue == nil {
                thumbnailViewTypes.removeValue(forKey: overlayIdentifier)
            } else {
                thumbnailViewTypes[overlayIdentifier] = newValue!.rawValue
            }
            UserSettings[.subredditsThumbnailSetting] = thumbnailViewTypes
        }
    }
    
}
