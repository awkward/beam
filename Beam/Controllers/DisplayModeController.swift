//
//  DisplayModeController.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum DisplayMode {
    case `default`
    case dark
}

extension Notification.Name {
    
    static let DisplayModeDidChange = Notification.Name(rawValue: "DisplayModeDidChangeNotification")
    
}

func DisplayModeValue<T>(_ defaultValue: T, darkValue: T) -> T {
    #if TARGET_INTERFACE_BUILDER
        return defaultValue
    #endif
    switch AppDelegate.shared.displayModeController.currentMode {
    case .dark:
        return darkValue
    default:
        return defaultValue
    }
}

class DisplayModeController: NSObject {
    
    var currentMode = DisplayMode.default {
        didSet {
            guard oldValue != currentMode else {
                return
            }
            NotificationCenter.default.post(name: .DisplayModeDidChange, object: nil)
        }
    }
    
    fileprivate var brightnessTimer: Timer?
    fileprivate let brightnessTimerInterval: TimeInterval = 1.0
    
    var brightnessReference: Float = 0.5 {
        didSet {
            if self.brightnessReference != oldValue {
                if let timer = brightnessTimer {
                    self.brightnessTimerFired(timer)
                }
            }
        }
    }
    
    var autoAdjustDisplayMode: Bool {
        get {
            return self.brightnessTimer != nil
        }
        set {
            if newValue {
                self.brightnessTimer = Timer.scheduledTimer(timeInterval: self.brightnessTimerInterval, target: self, selector: #selector(DisplayModeController.brightnessTimerFired(_:)), userInfo: nil, repeats: true)
                self.brightnessTimer?.tolerance = 1.0
                self.updateCurrentMode()
            } else {
                self.brightnessTimer?.invalidate()
                self.brightnessTimer = nil
                
            }
        }
    }
    
    var shouldUseDarkModeBasedOnBrightness: Bool {
        return UIScreen.main.brightness < CGFloat(self.brightnessReference)
    }
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(DisplayModeController.userSettingChanged(_:)), name: .SettingsDidChangeSetting, object: nil)
    }
    
    deinit {
        self.brightnessTimer?.invalidate()
    }
    
    @objc fileprivate func brightnessTimerFired(_ timer: Timer) {
        self.updateCurrentMode()
    }
    
    @objc func userSettingChanged(_ notification: Notification) {
        if notification.object as? SettingsKey == SettingsKeys.nightModeEnabled || notification.object as? SettingsKey == SettingsKeys.nightModeAutomaticEnabled || notification.object as? SettingsKey == SettingsKeys.nightModeAutomaticThreshold {
           self.updateSettings()
        }
    }
    
    func updateCurrentMode() {
        if UserSettings[.nightModeEnabled] {
            self.autoAdjustDisplayMode = false
            if self.currentMode != .dark {
                self.currentMode = .dark
            }
        } else if UserSettings[.nightModeAutomaticEnabled] && self.shouldUseDarkModeBasedOnBrightness {
            if self.currentMode != .dark {
                self.currentMode = .dark
            }
        } else {
            if self.currentMode != .default {
                    self.currentMode = .default
            }
        }
    }
    
    func updateSettings() {
        if UserSettings[.nightModeEnabled] {
            self.autoAdjustDisplayMode = false
        } else {
            self.autoAdjustDisplayMode = UserSettings[.nightModeAutomaticEnabled]

        }
        
        self.brightnessReference = UserSettings[.nightModeAutomaticThreshold]
        self.updateCurrentMode()
    }
    
}
