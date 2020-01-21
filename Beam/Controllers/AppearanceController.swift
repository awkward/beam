//
//  AppearanceController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

func AppearanceValue<T>(light: T, dark: T) -> T {
    switch AppDelegate.shared.appearanceController.window?.traitCollection.userInterfaceStyle {
    case .dark: return dark
    default: return light
    }
}

func AppearanceValue(light: UIColor, dark: UIColor) -> UIColor {
    UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark: return dark
        default: return light
        }
    }
}

/// Controller to observe dark mode setting changes,
/// and override the system appearance accordingly.
class AppearanceController: NSObject {
    
    weak var window: UIWindow? {
        didSet {
            window?.overrideUserInterfaceStyle = AppearanceController.systemOverride
        }
    }
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(AppearanceController.userSettingChanged(_:)), name: .SettingsDidChangeSetting, object: nil)
    }
    
    static private var systemOverride: UIUserInterfaceStyle {
        if UserSettings[.nightModeAutomaticEnabled] {
            return .unspecified
        } else if UserSettings[.nightModeEnabled] {
            return .dark
        } else {
            return .light
        }
    }
    
    @objc private func userSettingChanged(_ notification: Notification) {
        guard notification.object as? SettingsKey == SettingsKeys.nightModeEnabled ||
            notification.object as? SettingsKey == SettingsKeys.nightModeAutomaticEnabled else {
                return
        }
        window?.overrideUserInterfaceStyle = AppearanceController.systemOverride
    }
    
}
