//
//  BeamView.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamView: UIView, DynamicDisplayModeView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.registerForDisplayModeChangeNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        self.unregisterForDisplayModeChangeNotifications()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.displayModeDidChange()
        self.registerForDisplayModeChangeNotifications()
    }
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        self.displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        switch self.displayMode {
        case .dark:
            self.backgroundColor = UIColor.beamDarkContentBackgroundColor()
        case .default:
            self.backgroundColor = UIColor.beamBarColor()
        }
    }

}
