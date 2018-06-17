//
//  BeamCopyableLabel.swift
//  Beam
//
//  Created by Rens Verhoeven on 26-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamCopyableLabel: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.attachGestureRecognizers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.attachGestureRecognizers()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(UIResponderStandardEditActions.copy(_:)))
    }
    
    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = self.text
    }
    
    @objc func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        self.becomeFirstResponder()
        let menuController = UIMenuController.shared
        if let superView = self.superview, !menuController.isMenuVisible {
            menuController.setTargetRect(self.frame, in: superView)
            menuController.setMenuVisible(true, animated: true)
        }
    }
    
    func attachGestureRecognizers() {
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(BeamCopyableLabel.handleLongPress(_:))))
    }
    
}
