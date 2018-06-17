//
//  AppLaunchOptionsViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 12-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

class AppLaunchOptionsViewController: BeamTableViewController {
    
    private var supportedAppLaunchOptions: [String: [AppLaunchOption]] = [String: [AppLaunchOption]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = AWKLocalizedString("default-launch-screen-title")
        
        self.supportedAppLaunchOptions = AppLaunchOption.supportedAppLaunchOptions()
    }
    
    private func optionsForSection(_ section: Int) -> [AppLaunchOption]? {
        var key: String?
        switch section {
        case 0:
            key = "view"
        case 1:
            key = "subreddit"
        default:
            key = nil
        }
        guard let sectionKey = key else {
            return nil
        }
        return AppLaunchOption.supportedAppLaunchOptions()[sectionKey]
    }
    
    private func optionForIndexPath(_ indexPath: IndexPath) -> AppLaunchOption? {
        if let sectionValues = self.optionsForSection(indexPath.section) {
            guard indexPath.row < sectionValues.count else {
                return nil
            }
            return sectionValues[indexPath.row]
        }
        return nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.supportedAppLaunchOptions.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.optionsForSection(section)?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "app-open-cell", for: indexPath) as! SettingsTableViewCell
        let option = self.optionForIndexPath(indexPath)
        cell.textLabel?.text = option?.title
        cell.accessoryType = option == UserSettings[.appOpen] ? UITableViewCellAccessoryType.checkmark: UITableViewCellAccessoryType.none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return AWKLocalizedString("app-open-header-view")
        case 1:
            return AWKLocalizedString("app-open-header-subreddit")
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       UserSettings[.appOpen] = self.optionForIndexPath(indexPath) ?? AppLaunchOption.defaultAppLaunchOption
        self.tableView.reloadData()
    }

}
