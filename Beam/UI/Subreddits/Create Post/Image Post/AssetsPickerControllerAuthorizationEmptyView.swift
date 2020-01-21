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
    
    override func appearanceDidChange() {
        super.appearanceDidChange()
        self.backgroundColor = AppearanceValue(light: UIColor.beamBackground, dark: UIColor.beamDarkContentBackground)
        self.titleLabel.textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
        self.descriptionLabel.textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
    }
    
    @IBAction func openSettingsTapped(_ sender: AnyObject) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
