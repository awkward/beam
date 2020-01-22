//
//  AppearanceController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

/// Observes user appearance preferences, and overrides the app's user interface
/// style accordingly for the given window.
class AppearanceController: NSObject {
    
    /// The window to override the user interface style of, if needed.
    weak var window: UIWindow? {
        didSet {
            window?.overrideUserInterfaceStyle = AppearanceController.systemOverride
        }
    }
    
    /// The appropriate system UI style override settings, according to the
    /// current user preferences.
    static private var systemOverride: UIUserInterfaceStyle {
        if UserSettings[.nightModeAutomaticEnabled] {
            return .unspecified
        } else if UserSettings[.nightModeEnabled] {
            return .dark
        } else {
            return .light
        }
    }
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(AppearanceController.userSettingChanged(_:)), name: .SettingsDidChangeSetting, object: nil)
    }
    
    
    @objc private func userSettingChanged(_ notification: Notification) {
        guard notification.object as? SettingsKey == SettingsKeys.nightModeEnabled ||
            notification.object as? SettingsKey == SettingsKeys.nightModeAutomaticEnabled else {
                return
        }
        window?.overrideUserInterfaceStyle = AppearanceController.systemOverride
    }
    
}

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
