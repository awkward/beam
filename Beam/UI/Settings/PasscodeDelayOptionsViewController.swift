//
//  PasscodeDelayOptionsViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 12-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class PasscodeDelayOptionsViewController: BeamTableViewController {

    fileprivate var options: [PasscodeDelayOption] {
        return AppDelegate.shared.passcodeController.delayOptions
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = AWKLocalizedString("require-passcode-time-title")

        // Do any additional setup after loading the view.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.options.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settings-cell", for: indexPath) as! SettingsTableViewCell
        let option = self.options[(indexPath as IndexPath).row]
        cell.textLabel?.text = option.title
        cell.accessoryType = option.time == AppDelegate.shared.passcodeController.currentDelayOption?.time ? UITableViewCellAccessoryType.checkmark: UITableViewCellAccessoryType.none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = self.options[(indexPath as IndexPath).row]
        AppDelegate.shared.passcodeController.currentDelayOption = option
        self.tableView.reloadData()
    }

}
