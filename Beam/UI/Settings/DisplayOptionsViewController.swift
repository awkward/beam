//
//  DisplayOptionsViewController.swift
//  beam
//
//  Created by David van Leeuwen on 27/08/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class DisplayOptionsViewController: BeamTableViewController {
    
    @IBOutlet private var darkModeActiveCell: UITableViewCell!
    private let darkModeActiveSwitch = UISwitch()
    
    @IBOutlet private var darkModeAutomaticallyCell: UITableViewCell!
    private let darkModeAutomaticallySwitch = UISwitch()
    @IBOutlet private var darkModeAutomaticThresholdSlider: UISlider!
    
    @IBOutlet private var largeThumbnailsCell: UITableViewCell!
    @IBOutlet private var mediumThumbnailsCell: UITableViewCell!
    @IBOutlet private var smallThumbnailsCell: UITableViewCell!
    @IBOutlet private var noThumbnailsCell: UITableViewCell!
    
    @IBOutlet private var autoPlayGifsCell: UITableViewCell!
    private let autoPlayGifsSwitch = UISwitch()
    @IBOutlet private var autoPlayGifsOnCellularCell: UITableViewCell!
    private let autoPlayGifsOnCellularSwitch = UISwitch()
    
    @IBOutlet private var fontSizeCell: UITableViewCell!
    
    @IBOutlet private var showMetadataCell: UITableViewCell!
    private let showMetadataSwitch = UISwitch()
    
    @IBOutlet private var showMetadataDateCell: UITableViewCell!
    private let showMetadataDateSwitch = UISwitch()
    
    @IBOutlet private var showMetadataSubredditCell: UITableViewCell!
    private let showMetadataSubredditSwitch = UISwitch()
    
    @IBOutlet private var showMetadataUsernameCell: UITableViewCell!
    private let showMetadataUsernameSwitch = UISwitch()
    
    @IBOutlet private var showMetadataGildedCell: UITableViewCell!
    private let showMetadataGildedSwitch = UISwitch()
    
    @IBOutlet private var showMetadataDomainCell: UITableViewCell!
    private let showMetadataDomainSwitch = UISwitch()
    
    @IBOutlet private var showMetadataStickiedCell: UITableViewCell!
    private let showMetadataStickiedSwitch = UISwitch()
    
    @IBOutlet private var showMetadataLockedCell: UITableViewCell!
    private let showMetadataLockedSwitch = UISwitch()
    
    @IBOutlet private var cells: [UITableViewCell]!
    @IBOutlet private var controls: [UIControl]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = AWKLocalizedString("display-options-title")
        
        self.setupCells()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateSwitchStatuses()
        
        self.darkModeAutomaticThresholdSlider.value = UserSettings[.nightModeAutomaticThreshold]
        self.updateThumbnailCells()
        
    }
    
    func setupCells() {
        //Dark Mode active
        self.darkModeActiveSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.darkModeActiveCell.accessoryView = self.darkModeActiveSwitch
        self.darkModeActiveCell.textLabel?.text = AWKLocalizedString("display-options-cell-night-mode-manual")
        
        //Automatic dark mode
        self.darkModeAutomaticallySwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.darkModeAutomaticallyCell.accessoryView = self.darkModeAutomaticallySwitch
        self.darkModeAutomaticallyCell.textLabel?.text = AWKLocalizedString("display-options-cell-night-mode-automatic")
        
        //METADATA: Show metedata
        self.showMetadataSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.showMetadataCell.accessoryView = self.showMetadataSwitch
        self.showMetadataCell.textLabel?.text = AWKLocalizedString("display-options-cell-metadata-show")
        //METADATA: Show date
        self.showMetadataDateSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.showMetadataDateCell.accessoryView = self.showMetadataDateSwitch
        self.showMetadataDateCell.textLabel?.text = AWKLocalizedString("display-options-cell-metadata-date")
        //METADATA: Show subreddit
        self.showMetadataSubredditSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.showMetadataSubredditCell.accessoryView = self.showMetadataSubredditSwitch
        self.showMetadataSubredditCell.textLabel?.text = AWKLocalizedString("display-options-cell-metadata-subreddit")
        //METADATA: Show username
        self.showMetadataUsernameSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.showMetadataUsernameCell.accessoryView = self.showMetadataUsernameSwitch
        self.showMetadataUsernameCell.textLabel?.text = AWKLocalizedString("display-options-cell-metadata-username")
        //METADATA: Show Gilded
        self.showMetadataGildedSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.showMetadataGildedCell.accessoryView = self.showMetadataGildedSwitch
        self.showMetadataGildedCell.textLabel?.text = AWKLocalizedString("display-options-cell-metadata-gild-count")
        //METADATA: Show Domain
        self.showMetadataDomainSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.showMetadataDomainCell.accessoryView = self.showMetadataDomainSwitch
        self.showMetadataDomainCell.textLabel?.text = AWKLocalizedString("display-options-cell-metadata-domain")
        //METADATA: Show Stickied
        self.showMetadataStickiedSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.showMetadataStickiedCell.accessoryView = self.showMetadataStickiedSwitch
        self.showMetadataStickiedCell.textLabel?.text = AWKLocalizedString("display-options-cell-metadata-stickied")
        //METADATA: Show Locked
        self.showMetadataLockedSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.showMetadataLockedCell.accessoryView = self.showMetadataLockedSwitch
        self.showMetadataLockedCell.textLabel?.text = AWKLocalizedString("display-options-cell-metadata-locked")
        
        self.largeThumbnailsCell.textLabel?.text = AWKLocalizedString("display-options-cell-thumbnail-large")
        self.mediumThumbnailsCell.textLabel?.text = AWKLocalizedString("display-options-cell-thumbnail-medium")
        self.smallThumbnailsCell?.textLabel?.text = AWKLocalizedString("display-options-cell-thumbnail-small")
        self.noThumbnailsCell?.textLabel?.text = AWKLocalizedString("display-options-cell-thumbnail-none")
        
        self.autoPlayGifsSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.autoPlayGifsCell.accessoryView = self.autoPlayGifsSwitch
        self.autoPlayGifsCell.textLabel?.text = NSLocalizedString("display-options-cell-auto-play-gifs", comment: "The cell in the display options to disable/enable autoplaying gifs")
        
        self.autoPlayGifsOnCellularSwitch.addTarget(self, action: #selector(DisplayOptionsViewController.switchChanged(_:)), for: .valueChanged)
        self.autoPlayGifsOnCellularCell.accessoryView = self.autoPlayGifsOnCellularSwitch
        self.autoPlayGifsOnCellularCell.textLabel?.text = NSLocalizedString("display-options-cell-auto-play-gifs-cellular", comment: "The cell in the display options to disable/enable autoplaying gifs on cellular")
        
        self.fontSizeCell.textLabel?.text = NSLocalizedString("display-options-cell-fontsize", comment: "The title of the font size setting in display options")
        
        self.controls.append(self.darkModeActiveSwitch)
        self.controls.append(self.darkModeAutomaticallySwitch)
        self.controls.append(self.autoPlayGifsSwitch)
        self.controls.append(self.autoPlayGifsOnCellularSwitch)
        self.controls.append(self.showMetadataSwitch)
        self.controls.append(self.showMetadataDateSwitch)
        self.controls.append(self.showMetadataSubredditSwitch)
        self.controls.append(self.showMetadataUsernameSwitch)
        self.controls.append(self.showMetadataGildedSwitch)
        self.controls.append(self.showMetadataDomainSwitch)
        self.controls.append(self.showMetadataStickiedSwitch)
        self.controls.append(self.showMetadataLockedSwitch)
        
        self.updateSwitchStatuses()
    }
    
    @IBAction func darkMoreThresholdChanged(_ slider: UISlider) {
        UserSettings[.nightModeAutomaticThreshold] = slider.value
    }
    
    func updateSwitchStatuses() {
        //Dark Mode
        self.darkModeActiveSwitch.isOn = UserSettings[.nightModeEnabled]
        //Switch dark mode automaticly
        self.darkModeAutomaticallySwitch.isOn = UserSettings[.nightModeAutomaticEnabled]
        
        //Last switch dark mode automaticly
        self.darkModeAutomaticallySwitch.isEnabled = !UserSettings[.nightModeEnabled]
        //Last switch dark mode automaticly
        self.darkModeAutomaticThresholdSlider.isEnabled = !UserSettings[.nightModeEnabled]
        
        //Show metadata
        self.showMetadataSwitch.isOn = UserSettings[.showPostMetadata]
        //Show metadata date
        self.showMetadataDateSwitch.isOn = UserSettings[.showPostMetadataDate]
        //Show metadata subreddit
        self.showMetadataSubredditSwitch.isOn = UserSettings[.showPostMetadataSubreddit]
        //Show metadata username
        self.showMetadataUsernameSwitch.isOn = UserSettings[.showPostMetadataUsername]
        //Show metadata gilded
        self.showMetadataGildedSwitch.isOn = UserSettings[.showPostMetadataGilded]
        //Show metadata gilded
        self.showMetadataDomainSwitch.isOn = UserSettings[.showPostMetadataDomain]
        //Show metadata stickied
        self.showMetadataStickiedSwitch.isOn = UserSettings[.showPostMetadataStickied]
        //Show metadata locked
        self.showMetadataLockedSwitch.isOn = UserSettings[.showPostMetadataLocked]
        
        //Show metadata date
        self.showMetadataDateSwitch.isEnabled = UserSettings[.showPostMetadata]
        //Show metadata subreddit
        self.showMetadataSubredditSwitch.isEnabled = UserSettings[.showPostMetadata]
        //Show metadata username
        self.showMetadataUsernameSwitch.isEnabled = UserSettings[.showPostMetadata]
        //Show metadata gilded
        self.showMetadataGildedSwitch.isEnabled = UserSettings[.showPostMetadata]
        //Show metadata domain
        self.showMetadataDomainSwitch.isEnabled = UserSettings[.showPostMetadata]
        //Show metadata stickied
        self.showMetadataStickiedSwitch.isEnabled = UserSettings[.showPostMetadata]
        //Show metadata locked
        self.showMetadataLockedSwitch.isEnabled = UserSettings[.showPostMetadata]
        
        self.autoPlayGifsSwitch.isOn = UserSettings[.autoPlayGifsEnabled]
        self.autoPlayGifsSwitch.isEnabled = (UserSettings[.thumbnailsViewType] == .large || UserSettings[.thumbnailsViewType] == .medium)
        
        self.autoPlayGifsOnCellularSwitch.isOn = UserSettings[.autoPlayGifsEnabledOnCellular]
        self.autoPlayGifsOnCellularSwitch.isEnabled = UserSettings[.autoPlayGifsEnabled] && (UserSettings[.thumbnailsViewType] == .large || UserSettings[.thumbnailsViewType] == .medium)
    }
    
    @objc func switchChanged(_ sender: UISwitch?) {
        if let sender = sender {
            var callUpdateSwitches = false
            var key: SettingsKey<Bool>?
             if sender == self.darkModeActiveSwitch {
                key = .nightModeEnabled
                callUpdateSwitches = true
            } else if sender == self.darkModeAutomaticallySwitch {
                key = .nightModeAutomaticEnabled
            } else if sender == self.showMetadataSwitch {
                key = .showPostMetadata
                callUpdateSwitches = true
            } else if sender == self.showMetadataDateSwitch {
                key = .showPostMetadataDate
            } else if sender == self.showMetadataSubredditSwitch {
                key = .showPostMetadataSubreddit
            } else if sender == self.showMetadataUsernameSwitch {
                key = .showPostMetadataUsername
             } else if sender == self.showMetadataGildedSwitch {
                key = .showPostMetadataGilded
             } else if sender == self.showMetadataDomainSwitch {
                key = .showPostMetadataDomain
             } else if sender == self.showMetadataStickiedSwitch {
                key = .showPostMetadataStickied
             } else if sender == self.showMetadataLockedSwitch {
                key = .showPostMetadataLocked
             } else if sender == self.autoPlayGifsSwitch {
                callUpdateSwitches = true
                key = .autoPlayGifsEnabled
             } else if sender == self.autoPlayGifsOnCellularSwitch {
                key = .autoPlayGifsEnabledOnCellular
             } else {
                assert(false, "Unimplemented switch change")
            }
            if let key = key {
                UserSettings[key] = sender.isOn
            }
            if callUpdateSwitches {
                self.updateSwitchStatuses()
            }
            self.tableView.reloadData()
        }
    }
    
    func updateThumbnailCells() {
        self.fontSizeCell.detailTextLabel?.text = FontSizeController.displayTitle(forFontSizeCategory: FontSizeController.category)
        
        self.largeThumbnailsCell.accessoryType = .none
        self.mediumThumbnailsCell.accessoryType = .none
        self.smallThumbnailsCell.accessoryType = .none
        self.noThumbnailsCell.accessoryType = .none
        
        switch UserSettings[.thumbnailsViewType] {
        case .large:
            self.largeThumbnailsCell.accessoryType = .checkmark
        case .medium:
            self.mediumThumbnailsCell.accessoryType = .checkmark
        case .small:
            self.smallThumbnailsCell.accessoryType = .checkmark
        case .none:
            self.noThumbnailsCell.accessoryType = .checkmark
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as IndexPath).section == 1 {
            var thumbnailsType = ThumbnailsViewType.large
            if (indexPath as IndexPath).row == 1 {
                thumbnailsType = ThumbnailsViewType.medium
            } else if (indexPath as IndexPath).row == 2 {
                thumbnailsType = ThumbnailsViewType.small
            } else if (indexPath as IndexPath).row == 3 {
                thumbnailsType = ThumbnailsViewType.none
            }
            UserSettings[.thumbnailsViewType] = thumbnailsType
            self.updateThumbnailCells()
            self.updateSwitchStatuses()
        }
        if (indexPath as IndexPath).section == 3 {
            let fontSizeOptionsViewController: FontSizeOptionsViewController = storyboard?.instantiateViewController(withIdentifier: "font-size-options") as! FontSizeOptionsViewController
            self.show(fontSizeOptionsViewController, sender: indexPath)
            
        }
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 5 {
            return 5
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 4 {
            return 5
        }
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("display-options-header-night-mode", comment: "Header in the display options view for night mode")
        case 1:
            return NSLocalizedString("display-options-header-image-thumbnails", comment: "Header in the display options view for image thumbnails")
        case 2:
            return NSLocalizedString("display-options-header-gifs", comment: "Header in the display options view for gifs")
        case 3:
            return NSLocalizedString("display-options-header-font-size", comment: "Header in the display options view for font size")
        case 4:
            return NSLocalizedString("display-options-header-metadata", comment: "Header in the display options view for meta data")
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("display-options-footer-night-mode", comment: "The footer discribing automatic dark mode")
        default:
            return nil
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        switch self.displayMode {
        case .dark:
            self.darkModeAutomaticThresholdSlider.tintColor = UIColor.beamGreyLight()
            self.darkModeAutomaticThresholdSlider.minimumTrackTintColor = UIColor.beamPurpleLight()
        case .default:
            self.darkModeAutomaticThresholdSlider.tintColor = UIColor.beamGreyLight()
            self.darkModeAutomaticThresholdSlider.minimumTrackTintColor = UIColor.beamColor()
        }
    }
}
