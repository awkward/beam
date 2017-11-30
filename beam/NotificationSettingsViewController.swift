//
//  NotificationSettingsViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 13-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import CherryKit

class NotificationSettingsViewController: BeamTableViewController {
    
    @IBOutlet var messagesCell: BeamTableViewCell!
    @IBOutlet var shopCell: BeamTableViewCell!
    @IBOutlet var announcementsCell: BeamTableViewCell!
    
    var pushNotificationPreferences: RemoteNotificationsPreferences?
    
    lazy var messagesSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.addTarget(self, action: #selector(NotificationSettingsViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
        return switchControl
    }()
    
    lazy var shopSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.addTarget(self, action: #selector(NotificationSettingsViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
        return switchControl
    }()
    
    lazy var announcementsSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.addTarget(self, action: #selector(NotificationSettingsViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
        return switchControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = AWKLocalizedString("notifications-title")
        
        self.messagesCell.accessoryView = self.messagesSwitch
        self.shopCell.accessoryView = self.shopSwitch
        self.announcementsCell.accessoryView = self.announcementsSwitch
        
        self.messagesCell.textLabel?.text = AWKLocalizedString("notification-setting-messages")
        self.shopCell.textLabel?.text = AWKLocalizedString("notification-setting-shop")
        self.announcementsCell.textLabel?.text = AWKLocalizedString("notification-setting-announcements")
        
        self.updateSwitches()
        
        self.requestDeviceInformation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.updateDeviceInformation()
    }
    
    fileprivate func updateSwitches() {
        self.messagesSwitch.isEnabled = self.pushNotificationPreferences != nil && UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.available
        self.shopSwitch.isEnabled = self.pushNotificationPreferences != nil
        self.announcementsSwitch.isEnabled = self.pushNotificationPreferences != nil
        
        self.messagesSwitch.isOn = UserSettings[.redditMessageNotificationsEnabled]
        self.shopSwitch.isOn = self.pushNotificationPreferences?.shop == true
        self.announcementsSwitch.isOn = self.pushNotificationPreferences?.announcements == true
    }
    
    fileprivate func requestDeviceInformation() {
        if let deviceToken = AppDelegate.shared.deviceToken, let cherryToken = AppDelegate.shared.cherryController.accessToken {
            let task = RemoteNotificationsTask(token: cherryToken, deviceToken: deviceToken)
            task.start({ (taskResult) -> Void in
                if let pushTaskResult = taskResult as? RemoteNotificationsTaskResult {
                    DispatchQueue.main.async(execute: { () -> Void in
                        if let error = pushTaskResult.error {
                            AWKDebugLog("Could not fetch remote notification preferences: \(error)")
                        } else {
                            self.pushNotificationPreferences = pushTaskResult.preferences
                            self.updateSwitches()
                        }
                    })
                } else {
                    //Display an error to the user
                }
            })
        }
    }
    
    fileprivate func updateDeviceInformation() {
        if let deviceToken = AppDelegate.shared.deviceToken, let cherryToken = AppDelegate.shared.cherryController.accessToken, let preferences = self.pushNotificationPreferences {
            let appRelease = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
            let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
            
            #if DEBUG
                let usingSandbox = true
            #else
                let usingSandbox = false
            #endif
            
            var registrationOptions = RemoteNotificationsRegistrationOptions(appRelease: appRelease, appVersion: appVersion, sandboxed: usingSandbox, userNotificationsEnabled: true)
            registrationOptions.preferences = preferences
            let task = RemoteNotificationsRegistrationTask(token: cherryToken, deviceToken: deviceToken, registrationOptions: registrationOptions)
            task.start({ (taskResult) -> Void in
                if let pushTaskResult = taskResult as? RemoteNotificationsTaskResult {
                    DispatchQueue.main.async(execute: { () -> Void in
                        if let error = taskResult.error {
                            AWKDebugLog("Could not update remote notification device info: \(error)")
                        } else {
                            self.pushNotificationPreferences = pushTaskResult.preferences
                            self.updateSwitches()
                        }
                    })
                }
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            if UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.available {
                return AWKLocalizedString("background-refresh-available")
            } else {
                return AWKLocalizedString("background-refresh-unavailable")
            }
        }
        return nil
    }
    
    @objc fileprivate func switchChanged(_ sender: UISwitch) {
        if sender == self.announcementsSwitch {
            self.pushNotificationPreferences?.announcements = sender.isOn
            UserSettings[.announcementNotificationsEnabled] = sender.isOn
        } else if sender == self.shopSwitch {
            self.pushNotificationPreferences?.shop = sender.isOn
            UserSettings[.shopNotificationsEnabled] = sender.isOn
        } else if sender == self.messagesSwitch {
            self.pushNotificationPreferences?.messages = sender.isOn
            UserSettings[.redditMessageNotificationsEnabled] = sender.isOn
        }
        
        AppDelegate.shared.updateAnalyticsUser()
    }

}
