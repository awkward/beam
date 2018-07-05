//
//  PasscodeOptionsViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 08-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import LocalAuthentication

class PasscodeOptionsViewController: BeamTableViewController {
    
    fileprivate var passcodeController: PasscodeController {
        return AppDelegate.shared.passcodeController
    }
    
    fileprivate var touchIDSwitch = UISwitch()
    
    fileprivate var authenticationContext = LAContext()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = AWKLocalizedString("passcode-view-title")
        
        //Prepare the switches
        self.touchIDSwitch.addTarget(self, action: #selector(PasscodeOptionsViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
        self.updateSwitchState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadView()
    }
    
    // MARK: - Switches
    
    fileprivate func updateSwitchState() {
        //Touch ID
        self.touchIDSwitch.isEnabled = self.passcodeController.touchIDAvailable(self.authenticationContext)
        self.touchIDSwitch.isOn = self.passcodeController.touchIDEnabled(self.authenticationContext)
    }
    
    fileprivate func reloadView() {
        self.tableView.reloadData()
        self.updateSwitchState()
    }
    
    @objc fileprivate func switchChanged(_ sender: UISwitch) {
        if sender == self.touchIDSwitch {
            self.passcodeController.setTouchIDEnabled(sender.isOn)
        } else {
            assert(false, "Unimplemented switch")
        }
    }

    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.passcodeController.touchIDAvailable(self.authenticationContext) {
            return 3
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settings-cell", for: indexPath) as! SettingsTableViewCell
        //Reset the cell
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        cell.selectionStyle = UITableViewCellSelectionStyle.default
        cell.textColorType = .default
        cell.accessoryType = UITableViewCellAccessoryType.none
        //Edit the cell
        if (indexPath as IndexPath).section == 0 {
            cell.textColorType = .followAppTintColor
            switch (indexPath as IndexPath).row {
            case 0:
                if self.passcodeController.passcodeEnabled {
                    cell.textLabel?.text = AWKLocalizedString("turn-passcode-off-passcode-setting-title")
                } else {
                    cell.textLabel?.text = AWKLocalizedString("turn-passcode-on-passcode-setting-title")
                }
            case 1:
                if self.passcodeController.passcodeEnabled == false {
                    cell.textColorType = BeamTableViewCellTextColorType.disabled
                }
                cell.textLabel?.text = AWKLocalizedString("change-passcode-passcode-setting-title")
            default:
                break
            }
        } else if (indexPath as IndexPath).section == 1 {
            switch (indexPath as IndexPath).row {
            case 0:
                cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                cell.textLabel?.text = AWKLocalizedString("require-passcode-time-title")
                cell.detailTextLabel?.text = self.passcodeController.currentDelayOption?.title
            default:
                break
            }
        } else if (indexPath as IndexPath).section == 2 {
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            switch (indexPath as IndexPath).row {
            case 0:
                cell.accessoryView = self.touchIDSwitch
                cell.textLabel?.text = AWKLocalizedString("touch-id-passcode-setting-title")
            default:
                break
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath as IndexPath).section == 0 {
            switch (indexPath as IndexPath).row {
            case 0:
                if self.passcodeController.passcodeEnabled {
                    self.turnPasscodeOff()
                } else {
                    self.turnPasscodeOn()
                }
            case 1:
                self.changePasscode()
            default:
                break
            }
        } else if (indexPath as IndexPath).section == 1 {
            switch (indexPath as IndexPath).row {
            case 0:
                self.performSegue(withIdentifier: "passcode-delay-segue", sender: indexPath)
            default:
                break
            }
        }
    }
    
    fileprivate func turnPasscodeOn() {
        guard self.passcodeController.passcodeEnabled == false else {
            return
        }
        let storyboard = UIStoryboard(name: "Passcode", bundle: nil)
        if let navigationController = storyboard.instantiateViewController(withIdentifier: "enter-passcode") as? UINavigationController, let passcodeViewController = navigationController.topViewController as? EnterPasscodeViewController {
            passcodeViewController.delegate = self
            passcodeViewController.action = PasscodeAction.create
            self.showDetailViewController(navigationController, sender: nil)
        }
    }
    
    fileprivate func turnPasscodeOff() {
        guard self.passcodeController.passcodeEnabled else {
            return
        }
        let storyboard = UIStoryboard(name: "Passcode", bundle: nil)
        if let navigationController = storyboard.instantiateViewController(withIdentifier: "enter-passcode") as? UINavigationController, let passcodeViewController = navigationController.topViewController as? EnterPasscodeViewController {
            passcodeViewController.delegate = self
            passcodeViewController.action = PasscodeAction.check
            self.showDetailViewController(navigationController, sender: nil)
        }
        
    }
    
    fileprivate func changePasscode() {
        guard self.passcodeController.passcodeEnabled else {
            return
        }
        let storyboard = UIStoryboard(name: "Passcode", bundle: nil)
        if let navigationController = storyboard.instantiateViewController(withIdentifier: "enter-passcode") as? UINavigationController, let passcodeViewController = navigationController.topViewController as? EnterPasscodeViewController {
            passcodeViewController.delegate = self
            passcodeViewController.action = PasscodeAction.change
            self.showDetailViewController(navigationController, sender: nil)
        }
    }

}

extension PasscodeOptionsViewController: EnterPasscodeViewControllerDelegate {

    func passcodeViewController(_ viewController: EnterPasscodeViewController, didEnterPasscode passcode: String) -> Bool {
        if self.passcodeController.passcodeIsCorrect(passcode) {
            if viewController.action == PasscodeAction.check {
                viewController.dismiss(animated: true, completion: nil)
                do {
                    try self.passcodeController.removePasscode()
                } catch {
                    print("Error removing passcode \(error)")
                }
                self.reloadView()
            }
            return true
        } else {
            return false
        }
    }
    
    func passcodeViewControllerDidCancel(_ viewController: EnterPasscodeViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func passcodeViewController(_ viewController: EnterPasscodeViewController, didCreateNewPasscode passcode: String) {
        viewController.dismiss(animated: true, completion: nil)
        do {
            try self.passcodeController.savePasscode(passcode)
        } catch {
            print("Error saving passcode \(error)")
        }
        self.reloadView()
        
    }
    
    func passcodeViewControllerDidAuthenticateWithTouchID(_ viewController: EnterPasscodeViewController) {
        //Not used in the passcode options
    }
}
