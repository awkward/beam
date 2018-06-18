//
//  BannerNotification.swift
//  Beam
//
//  Created by Rens Verhoeven on 13-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import UserNotifications

enum BannerNotificationRequirementKey: String {
    case MinimumBuild = "min_build"
    case MaximumBuild = "max_build"
    
    case LoggedIn = "logged_in"
    case HasDonated = "has_donated"
    
    var userDefaultsKey: String? {
        switch self {
        case .HasDonated:
            return SettingsKeys.userHasDonated._key
        default:
            return nil
        }
    }
}

class BannerNotificationRequirement: NSObject {
    let key: BannerNotificationRequirementKey
    
    init?(keyString: String) {
        guard let key = BannerNotificationRequirementKey(rawValue: keyString) else {
            return nil
        }
        self.key = key
    }
    
    init(key: BannerNotificationRequirementKey) {
        self.key = key
    }
    
    var satisfied: Bool {
        assert(false, "Variable should be overwritten in subclasses")
        return false
    }
}

class BannerNotificationNumberRequirement: BannerNotificationRequirement {

    let number: Float
    let relation: String
    
    init(key: BannerNotificationRequirementKey, number: Float, relation: String) {
        self.number = number
        self.relation = relation
        super.init(key: key)
        
    }
    
    override var satisfied: Bool {
        var compareNumber: Float!
        if self.key == BannerNotificationRequirementKey.MinimumBuild || self.key == BannerNotificationRequirementKey.MaximumBuild {
            compareNumber = (Bundle.main.infoDictionary!["CFBundleVersion"] as! NSString).floatValue
        } else {
            if let userDefaultsKey = self.key.userDefaultsKey {
                compareNumber = UserDefaults.standard.float(forKey: userDefaultsKey)
            } else {
                return false
            }
        }
        
        if self.relation == ">=" {
            return compareNumber >= self.number
        } else if self.relation == "<=" {
            return compareNumber <= self.number
        } else if self.relation == ">" {
            return compareNumber > self.number
        } else if self.relation == "<" {
           return compareNumber < self.number
        } else if self.relation == "!=" {
            return compareNumber != self.number
        } else {
            return compareNumber == self.number
        }
    }
}

class BannerNotificationBooleanRequirement: BannerNotificationRequirement {
    
    var booleanValue: Bool
    
    init(key: BannerNotificationRequirementKey, booleanValue: Bool) {
        self.booleanValue = booleanValue
        super.init(key: key)
        
    }
    
    override var satisfied: Bool {
        if self.key == BannerNotificationRequirementKey.LoggedIn {
            return self.booleanValue == AppDelegate.shared.authenticationController.isAuthenticated
        } else if let userDefaultsKey = self.key.userDefaultsKey {
            return self.booleanValue == UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
        return false
    }
}

class BannerNotification: NSObject {
    
    let identifier: String
    let analyticsTitle: String
    let message: String
    var useRoundIcon = false
    var iconURL: URL?
    var iconName: String?
    let customInfo: [AnyHashable: Any]
    let requirements: [BannerNotificationRequirement]
    
    init?(dictionary: [AnyHashable: Any]) {
        guard let identifier = dictionary["id"] as? String, let message = dictionary["message"] as? String, let iconString = dictionary["icon"] as? String, let customInfo = dictionary["beam"] as? [AnyHashable: Any], let requirements = dictionary["requirements"] as? [String: AnyObject] else {
            return nil
        }
        guard identifier != "free_packs_accouncement" else {
            return nil
        }
        self.identifier = identifier
        if let analyticsTitle = dictionary["analytics_title"] as? String {
            self.analyticsTitle = analyticsTitle
        } else {
            self.analyticsTitle = self.identifier
        }
        self.message = message
        if iconString.hasPrefix("http") {
            self.iconURL = URL(string: iconString)
        } else {
            self.iconName = iconString
        }
        self.useRoundIcon = (dictionary["round_icon"] as? Bool) ?? false
        self.customInfo = customInfo
        
        //Parse the requirements
        var requirementObjects = [BannerNotificationRequirement]()
        for (keyString, value) in requirements {
            if let key = BannerNotificationRequirementKey(rawValue: keyString) {
                switch key {
                case .MaximumBuild, .MinimumBuild:
                    if let count = value as? Int {
                        let requirement = BannerNotificationNumberRequirement(key: key, number: Float(count), relation: key == .MinimumBuild ? ">=" : "<=")
                        requirementObjects.append(requirement)
                    }
                default:
                    break
                }
            } else {
                print("Invalid requirement \(keyString)")
            }
        }
        self.requirements = requirementObjects
        
    }
    
    var shouldDisplay: Bool {
        guard self.hasBeenShown() == false else {
            return false
        }
        return !self.requirements.contains { (requirement) -> Bool in
            return !requirement.satisfied
        }
    }
    
    func hasBeenShown() -> Bool {
        if let shownBanners = UserSettings[.shownBanners] {
            return shownBanners.contains(self.identifier)
        }
        return false
    }
    
    func markAsShown(_ mark: Bool = true) {
        if mark {
            var shownBanners = UserSettings[.shownBanners]
            if shownBanners == nil {
                shownBanners = [String]()
            }
            shownBanners!.append(self.identifier)
            UserSettings[.shownBanners] = shownBanners!
        } else {
            if self.hasBeenShown() {
                //We know for sure the banners exist otherwise this method would return false
                var shownBanners = UserSettings[.shownBanners]!
                if let index = shownBanners.index(of: self.identifier) {
                    shownBanners.remove(at: index)
                }
                UserSettings[.shownBanners] = shownBanners
            }
        }
    }
    
    var userNotificationContent: UNNotificationContent {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = self.analyticsTitle
        notificationContent.body = self.message
        notificationContent.userInfo = ["beam": customInfo]
        return notificationContent
    }
    
}
