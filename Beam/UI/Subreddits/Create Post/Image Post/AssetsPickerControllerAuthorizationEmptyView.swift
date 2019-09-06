//
//  AssetsPickerControllerAuthorizationEmptyView.swift
//  Beam
//
//  Created by Rens Verhoeven on 14-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class AssetsPickerControllerAuthorizationEmptyView: BeamView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var settingsButton: BeamButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.reloadContents()
    }
    
    fileprivate func reloadContents() {
        self.titleLabel.text = AWKLocalizedString("assets-picker-no-access-title")
        self.descriptionLabel.text = AWKLocalizedString("assets-picker-no-access-message")
        self.settingsButton.setTitle(AWKLocalizedString("go-to-settings-button"), for: UIControl.State())
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.backgroundColor = DisplayModeValue(UIColor.beamBackground(), darkValue: UIColor.beamDarkContentBackgroundColor())
        self.titleLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.descriptionLabel.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
    }
    
    @IBAction func openSettingsTapped(_ sender: AnyObject) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
