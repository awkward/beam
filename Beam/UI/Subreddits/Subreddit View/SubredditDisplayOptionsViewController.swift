//
//  SubredditDisplayOptionsViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 09-05-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

class SubredditDisplayOptionsViewController: BeamTableViewController {

    var subreddit: Subreddit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = AWKLocalizedString("display-options-title")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingscell", for: indexPath) as! SettingsTableViewCell

        var showsCheckmark = false
        switch (indexPath as IndexPath).row {
        case 0:
            cell.textLabel?.text = AWKLocalizedString("display-options-cell-thumbnail-default")
            showsCheckmark = self.subreddit?.thumbnailViewType == nil
        case 1:
            cell.textLabel?.text = AWKLocalizedString("display-options-cell-thumbnail-large")
            showsCheckmark = self.subreddit?.thumbnailViewType == ThumbnailsViewType.large
        case 2:
            cell.textLabel?.text = AWKLocalizedString("display-options-cell-thumbnail-medium")
            showsCheckmark = self.subreddit?.thumbnailViewType == ThumbnailsViewType.medium
        case 3:
            cell.textLabel?.text = AWKLocalizedString("display-options-cell-thumbnail-small")
            showsCheckmark = self.subreddit?.thumbnailViewType == ThumbnailsViewType.small
        case 4:
            cell.textLabel?.text = AWKLocalizedString("display-options-cell-thumbnail-none")
            showsCheckmark = self.subreddit?.thumbnailViewType == ThumbnailsViewType.none
        default:
            cell.textLabel?.text = nil
        }
        
        cell.textColorType = BeamTableViewCellTextColorType.default
        cell.accessoryType = showsCheckmark ? UITableViewCellAccessoryType.checkmark: UITableViewCellAccessoryType.none
        cell.selectionStyle = UITableViewCellSelectionStyle.default

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath as IndexPath).row {
        case 0:
            self.subreddit?.thumbnailViewType = nil
        case 1:
            self.subreddit?.thumbnailViewType = ThumbnailsViewType.large
        case 2:
            self.subreddit?.thumbnailViewType = ThumbnailsViewType.medium
        case 3:
            self.subreddit?.thumbnailViewType = ThumbnailsViewType.small
        case 4:
            self.subreddit?.thumbnailViewType = ThumbnailsViewType.none
        default:
            break
        }
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return AWKLocalizedString("display-options-header-image-thumbnails")
        default:
            return nil
        }
    }

}
