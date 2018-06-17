//
//  OpenLinksOptionsViewController.swift
//  beam
//
//  Created by Rens Verhoeven on 07-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class OpenLinksOptionsViewController: BeamTableViewController {
    
    fileprivate lazy var readerModeSwitch: UISwitch = {
        let control = UISwitch()
        control.addTarget(self, action: #selector(OpenLinksOptionsViewController.readerModeSwitchChanged(sender:)), for: .valueChanged)
        return control
    }()

    var supportedLinkOptions: [ExternalLinkOpenOption] = [ExternalLinkOpenOption]()
    var supportedYouTubeOptions: [ExternalLinkOpenOption] = [ExternalLinkOpenOption]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.supportedLinkOptions = ExternalLinkOpenOption.availableOptionsForLinks()
        self.supportedYouTubeOptions = ExternalLinkOpenOption.availableOptionsForYouTubeLinks()
         
        self.navigationItem.title = NSLocalizedString("open-links-options-view-title", comment: "Title of \"Open links in\" view")
    }
    
    @objc fileprivate func readerModeSwitchChanged(sender: UISwitch) {
        UserSettings[.prefersSafariViewControllerReaderMode] = sender.isOn
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if UserSettings[.browser] == .safari {
            return 3
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.supportedLinkOptions.count
        case 1:
            return self.supportedYouTubeOptions.count
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("open-links-in-header-title", comment: "Table View header title for \"Open links in\" view")
        case 1:
            return NSLocalizedString("open-youtube-links-in-header-title", comment: "Table View header title for \"Open links in\" view")
        default:
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "option-cell", for: indexPath) as! SettingsTableViewCell
        
        var title = NSLocalizedString("unknown-link-option", comment: "If the option is unknown")
        var selected = false
        var accesoryView: UIView? = nil
        switch indexPath.section {
        case 0:
            let option = self.supportedLinkOptions[(indexPath as IndexPath).row]
            title = option.displayName
            selected = option == UserSettings[.browser]
        case 1:
            let option = self.supportedYouTubeOptions[(indexPath as IndexPath).row]
            title = option.displayName
            selected = option == UserSettings[.youTubeApp]
        case 2:
            title = NSLocalizedString("open-in-reader-if-available", comment: "The options displayed in 'open links in' to prefer reader mode")
            selected = false
            self.readerModeSwitch.isOn = UserSettings[.prefersSafariViewControllerReaderMode]
            accesoryView = self.readerModeSwitch
        default:
            
            break
            
        }
        
        cell.textLabel?.text = title
        cell.accessoryType = selected ? .checkmark : .none
        cell.accessoryView = accesoryView
        
        return cell

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as IndexPath).section == 0 {
            UserSettings[.browser] = self.supportedLinkOptions[(indexPath as IndexPath).row]
        } else if (indexPath as IndexPath).section == 1 {
            UserSettings[.youTubeApp] = self.supportedYouTubeOptions[(indexPath as IndexPath).row]
        }
        self.tableView.reloadData()
    }

}
