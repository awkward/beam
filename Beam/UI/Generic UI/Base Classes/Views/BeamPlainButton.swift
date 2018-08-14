//
//  BeamPlainButton.swift
//  Beam
//
//  Created by Rens Verhoeven on 17-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class BeamPlainButton: UIButton, DynamicDisplayModeView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.registerForDisplayModeChangeNotifications()
        self.setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.registerForDisplayModeChangeNotifications()
        self.setupButton()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.displayModeDidChange()
        self.registerForDisplayModeChangeNotifications()
        self.setupButton()
    }
    
    deinit {
        self.unregisterForDisplayModeChangeNotifications()
    }
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        self.displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        if self.buttonType == .system {
            self.tintColor = UIColor.white
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if self.buttonType == .custom {
                self.titleLabel?.alpha = isEnabled ? 1: 0.5
                self.imageView?.alpha = isEnabled ? 1: 0.5
            }
        }
    }
    
    func setupButton() {
        self.adjustsImageWhenHighlighted = false
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: 44)
    }
    
    override var isHighlighted: Bool {
        didSet {
            guard self.buttonType == .custom else {
                return
            }
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                self.titleLabel?.alpha = self.isHighlighted ? 0.5: 1
                self.imageView?.alpha = self.isHighlighted ? 0.5: 1
                }, completion: nil)
        }
    }

}
