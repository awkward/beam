//
//  NoAccessEmptyView.swift
//  AssetsPickerControllerExample
//
//  Created by Rens Verhoeven on 14-04-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

internal class NoAccessEmptyView: UIView, ColorPaletteSupport {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var descriptionLabelToSettingsButtonConstraint: NSLayoutConstraint!
    
    weak var assetsPickerController: AssetsPickerController? {
        didSet {
            self.startColorPaletteSupport()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.reloadContents()
    }
    
    deinit {
        self.stopColorPaletteSupport()
    }
    
    func reloadContents() {
        var appName = "Image Picker"
        if let name = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            appName = name
        }
        if let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            appName = name
        }
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.notDetermined {
            self.titleLabel.text = NSLocalizedString("requesting-access-message-title", tableName: nil, bundle: Bundle(for: AuthorizationViewController.self), value: "Requesting access", comment: "The title shown when the app is requesting access to the photos")
            self.descriptionLabel.text = NSLocalizedString("no-access-message", tableName: nil, bundle: Bundle(for: AuthorizationViewController.self), value: "Tap allow to give [APPNAME] access to your photos library", comment: "The message shown when the access to photos is being requested.").replacingOccurrences(of: "[APPNAME]", with: appName)
            self.descriptionLabelToSettingsButtonConstraint.isActive = false
        } else {
            self.titleLabel.text = NSLocalizedString("no-access-message-title", tableName: nil, bundle: Bundle(for: AuthorizationViewController.self), value: "No access", comment: "The title at the top of the \"no access\" message when the access to photos is denied or restricted.")
            self.descriptionLabel.text = NSLocalizedString("no-access-message", tableName: nil, bundle: Bundle(for: AuthorizationViewController.self), value: "Please allow '[APPNAME]' access to photos in the Settings app", comment: "The message shown when the access to photos is denied or restricted.").replacingOccurrences(of: "[APPNAME]", with: appName)
            let buttonTitle = NSLocalizedString("open-settings-button", tableName: nil, bundle: Bundle(for: AuthorizationViewController.self), value: "Open settings", comment: "The button shown at the bottom of the view to let the user access settings")
            self.settingsButton.setTitle(buttonTitle, for: UIControlState())
            self.descriptionLabelToSettingsButtonConstraint.isActive = true
        }
    }
    
    func colorPaletteDidChange() {
        self.backgroundColor = self.colorPalette.backgroundColor
        self.titleLabel.textColor = self.colorPalette.titleColor
        self.descriptionLabel.textColor = self.colorPalette.titleColor
    }
    
    @IBAction func openSettingsTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
    }

}
