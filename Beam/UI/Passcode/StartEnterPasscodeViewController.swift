//
//  StartEnterPasscodeViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 08-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import LocalAuthentication

class StartEnterPasscodeViewController: EnterPasscodeViewController {
    
    @IBOutlet var touchIDButton: UIButton!
    
    var authenticationContext: LAContext?
    
    var canShowTouchID: Bool = true
    
    var passcodeController: PasscodeController {
        return AppDelegate.shared.passcodeController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(StartEnterPasscodeViewController.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        if self.passcodeController.touchIDEnabled(LAContext()) {
            self.touchIDButton.setImage(UIImage(named: "touch-id-icon"), for: UIControl.State())
        } else {
            self.touchIDButton.setImage(nil, for: UIControl.State())
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func touchIDTapped(_ sender: UIButton) {
        self.canShowTouchID = true
        self.startTouchID()
    }
    
    @objc fileprivate func applicationDidBecomeActive(_ notification: Notification) {
        self.createAuthenticationContext()
        if self.passcodeController.touchIDEnabled(LAContext()) {
            self.touchIDButton.setImage(UIImage(named: "touch-id-icon"), for: UIControl.State())
        } else {
            self.touchIDButton.setImage(nil, for: UIControl.State())
        }
        self.startTouchID()
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    fileprivate func startTouchID() {
        self.createAuthenticationContext()
        if self.passcodeController.touchIDEnabled(self.authenticationContext!) && self.canShowTouchID == true {
            self.canShowTouchID = false
            
            let reason = AWKLocalizedString("touch-id-reason").replacingOccurrences(of: "[APPNAME]", with: self.appName)
            self.authenticationContext!.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: { (successful, _) in
                self.invalidAuthenticationContext()
                if successful {
                    DispatchQueue.main.async(execute: {
                        self.enteredString = "1234"
                        self.updateIndicators()
                        self.delegate.passcodeViewControllerDidAuthenticateWithTouchID(self)
                    })
                }
            })
        }
    }
    
    func createAuthenticationContext() {
        if self.authenticationContext == nil {
            self.authenticationContext = LAContext()
        }
    }
    
    func invalidAuthenticationContext() {
        self.authenticationContext = nil
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func appearanceDidChange() {
        super.appearanceDidChange()
        self.titleLabel?.textColor = UIColor.white
        self.view.backgroundColor = AppearanceValue(light: UIColor.beam, dark: UIColor.beamPurpleLight)
        self.view.tintColor = UIColor.white
    }
    
}
