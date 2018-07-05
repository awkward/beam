//
//  PasscodeController.swift
//  Beam
//
//  Created by Rens Verhoeven on 11-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import LocalAuthentication

struct PasscodeDelayOption {
    let title: String
    //In seconds
    let time: TimeInterval
}

class PasscodeController: NSObject {
    
    fileprivate let passcodeKey = "BeamPasscodeKey"
    fileprivate let PasscodeEnabledSettingKey = "BeamPasscodeEnabled"
    fileprivate let PasscodeTouchIDEnabledSettingKey = "BeamPasscodeTouchIDEnabled"
    fileprivate let PasscodeDelaySettingKey = "BeamPasscodeDelay"
    
    var passcodeEnabled: Bool {
        return UserDefaults.standard.bool(forKey: PasscodeEnabledSettingKey)
    }
    
    var currentDelayOption: PasscodeDelayOption? {
        get {
            let time = UserDefaults.standard.double(forKey: PasscodeDelaySettingKey)
            return self.delayOptions.first(where: { $0.time == time })
        }
        set {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: PasscodeDelaySettingKey)
            } else {
                UserDefaults.standard.set(newValue!.time, forKey: PasscodeDelaySettingKey)
            }
        }
        
    }
    
    /// True if the app has already unlocked the app once this session. Either using Touch ID or Passcode.
    /// This is to fix the issue where quickly closing and relaunching the app would count as "X minutes not elapsed".
    /// Now the "require passcode after" setting only works if the app has been unlocked once in this session.
    var hasBeenUnlockedOnce: Bool = false
    
    var unlocked: Bool {
        get {
            guard self.passcodeEnabled == true else {
                return true
            }
            return self.cachedUnlocked
        }
        set {
            self.cachedUnlocked = newValue
        }
    }
    
    fileprivate var cachedUnlocked: Bool = false
    
    var delayOptions = [
        PasscodeDelayOption(title: AWKLocalizedString("require-passcode-time-immediately"), time: 0),
        PasscodeDelayOption(title: AWKLocalizedString("require-passcode-time-1-minute"), time: 60),
        PasscodeDelayOption(title: AWKLocalizedString("require-passcode-time-5-minutes"), time: 300),
        PasscodeDelayOption(title: AWKLocalizedString("require-passcode-time-15-minutes"), time: 900),
        PasscodeDelayOption(title: AWKLocalizedString("require-passcode-time-1-hour"), time: 3600)
    ]
    
    fileprivate var cachedPasscode: String?
    
    fileprivate var passcode: String? {
        get {
            if self.cachedPasscode == nil {
                do {
                    if let stringData = try Keychain.load(self.passcodeKey), let passcode = String(data: stringData, encoding: String.Encoding.utf8) {
                        self.cachedPasscode = passcode
                    }
                    
                } catch {
                    print("Error loading passcode  \(error)")
                }
            }
            return self.cachedPasscode
           
        }
        set {
            self.cachedPasscode = newValue
        }
    }
    
    var passcodeWindow: UIWindow?
    
    func createPasscodeWindow() {
        guard self.passcodeWindow == nil else {
            return
        }
        let window = UIWindow(frame: UIScreen.main.bounds)
        //Start the window behind the main window on level 0
        window.windowLevel = -1
        self.passcodeWindow = window
    }
    
    fileprivate var enteredBackgroundTime: Date?
    
    override init() {
        super.init()
        self.createPasscodeWindow()
    }
    
    func touchIDAvailable(_ context: LAContext) -> Bool {
        return context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    func touchIDEnabled(_ context: LAContext) -> Bool {
        guard self.touchIDAvailable(context) else {
            return false
        }
        guard UserDefaults.standard.object(forKey: PasscodeTouchIDEnabledSettingKey) != nil else {
            return true
        }
        return UserDefaults.standard.bool(forKey: PasscodeTouchIDEnabledSettingKey)
    }
    
    func setTouchIDEnabled(_ enabled: Bool) {
         UserDefaults.standard.set(enabled, forKey: PasscodeTouchIDEnabledSettingKey)
    }
    
    func passcodeIsCorrect(_ passcode: String) -> Bool {
        if self.passcode == nil {
            return false
        }
        if passcode == self.passcode {
            return true
        } else {
            return false
        }
    }
    
    func savePasscode(_ passcode: String) throws {
        try Keychain.save(self.passcodeKey, data: passcode.data(using: String.Encoding.utf8)!)
        UserDefaults.standard.set(true, forKey: PasscodeEnabledSettingKey)
        self.cachedPasscode = passcode
    }
    
    func removePasscode() throws {
        try Keychain.delete(self.passcodeKey)
        UserDefaults.standard.removeObject(forKey: PasscodeEnabledSettingKey)
        self.cachedPasscode = nil
    }
    
    //Using notifications for this mehod is too unreliable because of the snapshots in iOS 7+ altough they are mentioned in the offical answer: https://developer.apple.com/library/ios/qa/qa1838/_index.html
    func applicationWillEnterForeground(_ application: UIApplication) {
        if let enteredBackgroundTime = self.enteredBackgroundTime {
            let timeInterval = Date().timeIntervalSince(enteredBackgroundTime)
            if let currentDelayOption = self.currentDelayOption, timeInterval < currentDelayOption.time  && currentDelayOption.time > 0 && self.hasBeenUnlockedOnce {
                self.dismissPasscodeWindow(false)
            }
        }
    }
    
    //Using notifications for this mehod is too unreliable because of the snapshots in iOS 7+ altough they are mentioned in the offical answer: https://developer.apple.com/library/ios/qa/qa1838/_index.html
    func applicationDidEnterBackground(_ applicarion: UIApplication) {
        self.presentPasscodeWindow()
        self.enteredBackgroundTime = Date()
        self.unlocked = false
    }
    
    func presentPasscodeWindow() {
        guard self.passcodeEnabled == true else {
            return
        }
        self.createPasscodeWindow()
        //Bring the window in front of all windows, including the status bar
        self.passcodeWindow?.windowLevel = UIWindowLevelAlert + 300
        //Reset this before the view is shown
        let storyboard = UIStoryboard(name: "Passcode", bundle: nil)
        let passcodeViewController = storyboard.instantiateViewController(withIdentifier: "start-enter-passcode") as! StartEnterPasscodeViewController
        passcodeViewController.delegate = self
        passcodeViewController.view.frame = UIScreen.main.bounds
        self.passcodeWindow!.rootViewController = passcodeViewController
        self.passcodeViewController?.canShowTouchID = true
        UIView.performWithoutAnimation {
            AppDelegate.topViewController()?.view.endEditing(true)
            AppDelegate.shared.isWindowUsable = false
            self.passcodeWindow!.makeKeyAndVisible()
        }
        
    }
    
    func dismissPasscodeWindow(_ animated: Bool = true) {
        var duration = 0.2
        if !animated {
            duration = 0
        }
        
        self.passcodeViewController?.canShowTouchID = false
        UIView.animate(withDuration: duration, animations: {
            self.passcodeWindow!.alpha = 0
            AppDelegate.topViewController()?.setNeedsStatusBarAppearanceUpdate()
            }, completion: { (_) in
                self.passcodeWindow!.resignKey()
                if AppDelegate.shared.galleryWindow != nil {
                    AppDelegate.shared.galleryWindow?.makeKeyAndVisible()
                } else {
                    AppDelegate.shared.window?.makeKeyAndVisible()
                }
                //Bring the window behind the main window at level 0, this is because the status bar listens to the top window
                self.passcodeWindow!.windowLevel = -1
                self.passcodeWindow!.alpha = 1
                AppDelegate.topViewController()?.setNeedsStatusBarAppearanceUpdate()
                self.passcodeViewController?.reset()
                self.passcodeWindow!.isUserInteractionEnabled = false
                self.passcodeWindow!.rootViewController = nil
                self.passcodeWindow = nil
                self.createPasscodeWindow()
                self.unlocked = true
                AppDelegate.shared.isWindowUsable = true
        })
    }
    
    var passcodeViewController: StartEnterPasscodeViewController? {
        if let passcodeViewController = self.passcodeWindow?.rootViewController as? StartEnterPasscodeViewController {
            return passcodeViewController
        }
        return nil
    }

}

extension PasscodeController: EnterPasscodeViewControllerDelegate {
    
    func passcodeViewController(_ viewController: EnterPasscodeViewController, didEnterPasscode passcode: String) -> Bool {
        if viewController == self.passcodeWindow?.rootViewController {
            if self.passcodeIsCorrect(passcode) {
                self.hasBeenUnlockedOnce = true
                self.dismissPasscodeWindow()
                return true
            }
        }
        return false
    }
    
    func passcodeViewControllerDidCancel(_ viewController: EnterPasscodeViewController) {
        if viewController != self.passcodeWindow?.rootViewController {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func passcodeViewController(_ viewController: EnterPasscodeViewController, didCreateNewPasscode passcode: String) {
        if viewController != self.passcodeWindow?.rootViewController {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func passcodeViewControllerDidAuthenticateWithTouchID(_ viewController: EnterPasscodeViewController) {
        if viewController == self.passcodeWindow?.rootViewController {
            self.hasBeenUnlockedOnce = true
            self.dismissPasscodeWindow()
        }
    }
}
