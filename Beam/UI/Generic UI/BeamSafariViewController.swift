//
//  BeamSafariViewController.swift
//  beam
//
//  Created by Robin Speijer on 16-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import SafariServices

final class BeamSafariViewController: SFSafariViewController {
    
    init(url URL: URL) {
        super.init(url: URL, entersReaderIfAvailable: UserSettings[.prefersSafariViewControllerReaderMode])
        if #available(iOS 10.0, *), AppDelegate.shared.displayModeController.currentMode == .dark {
            self.preferredBarTintColor = UIColor.black
            self.preferredControlTintColor = UIColor.white
        }
    }
    
    override init(url URL: URL, entersReaderIfAvailable: Bool) {
        super.init(url: URL, entersReaderIfAvailable: entersReaderIfAvailable)
        if #available(iOS 10.0, *), AppDelegate.shared.displayModeController.currentMode == .dark {
            self.preferredBarTintColor = UIColor.black
            self.preferredControlTintColor = UIColor.white
        }
    }

}
