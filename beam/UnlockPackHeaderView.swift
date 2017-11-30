//
//  UnlockPackHeaderView.swift
//  Beam
//
//  Created by Rens Verhoeven on 23-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum UnlockPackHeaderViewFeature {
    case displayOptions
    case addAccount
    case passcode
    
    var storeProduct: StoreProduct {
        switch self {
        case .displayOptions:
            return StoreProduct(identifier: ProductDisplayPackIdentifier)
        default:
            return StoreProduct(identifier: ProductIdentityPackIdentifier)
        }
    }
    
    var text: String {
        switch self {
        case .displayOptions:
            return AWKLocalizedString("display-options-unlock-text")
        case .addAccount:
            return AWKLocalizedString("add-account-unlock-text")
        case .passcode:
            return AWKLocalizedString("passcode-unlock-text")
        }
    }
}

class UnlockPackHeaderView: BeamView {
    
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var button: BeamButton!
    
    var feature: UnlockPackHeaderViewFeature = UnlockPackHeaderViewFeature.displayOptions {
        didSet {
            self.reloadText()
            self.invalidateIntrinsicContentSize()
        }
    }
    
    var tapHandler: ((_ product: StoreProduct, _ button: UIButton) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.button.setTitle(AWKLocalizedString("view-pack-button"), for: UIControlState())
        self.reloadText()
    }
    
    fileprivate func reloadText() {
        self.textLabel.text = self.feature.text
    }
    
    @objc @IBAction fileprivate func unlockButtonTapped(_ sender: UIButton) {
        BeamSoundType.tap.play()
        self.tapHandler?(self.feature.storeProduct, sender)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.textLabel.textColor = DisplayModeValue(UIColor(red:0.65, green:0.65, blue:0.67, alpha:1), darkValue: UIColor.white)
    }

}
