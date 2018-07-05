//
//  ImagePostCollectionHeaderView.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class ImagePostCollectionHeaderView: BeamCollectionReusableView {
    
    @IBOutlet var titleTextFieldHolder: UIView!
    @IBOutlet var titleTextFieldHolderHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var descriptionTextFieldHolder: UIView!
    @IBOutlet var descriptionTextFieldHolderHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var seperatorView: UIView!
    @IBOutlet var seperatorViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.seperatorViewHeightConstraint.constant = 1 / UIScreen.main.scale
    }
    
    var titleTextField: UITextField? {
        didSet {
            if let titleTextField = self.titleTextField {
                self.titleTextFieldHolder.addSubview(titleTextField)
                titleTextField.translatesAutoresizingMaskIntoConstraints = false
                self.titleTextFieldHolder.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[textField]|", options: [], metrics: nil, views: ["textField": titleTextField]))
                self.titleTextFieldHolder.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[textField]|", options: [], metrics: nil, views: ["textField": titleTextField]))
                self.titleTextFieldHolderHeightConstraint.constant = titleTextField.intrinsicContentSize.height
            } else {
                if oldValue?.superview == self.titleTextFieldHolder {
                    oldValue?.removeFromSuperview()
                }
            }
        }
    }
    
    var descriptionTextField: UITextField? {
        didSet {
            if let descriptionTextField = self.descriptionTextField {
                self.descriptionTextFieldHolder.addSubview(descriptionTextField)
                descriptionTextField.translatesAutoresizingMaskIntoConstraints = false
                self.descriptionTextFieldHolder.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[textField]|", options: [], metrics: nil, views: ["textField": descriptionTextField]))
                self.descriptionTextFieldHolder.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[textField]|", options: [], metrics: nil, views: ["textField": descriptionTextField]))
                self.descriptionTextFieldHolderHeightConstraint.constant = descriptionTextField.intrinsicContentSize.height
            } else {
                if oldValue?.superview == self.descriptionTextFieldHolder {
                    oldValue?.removeFromSuperview()
                }
            }
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.titleTextFieldHolder.backgroundColor = backgroundColor
        self.descriptionTextFieldHolder.backgroundColor = backgroundColor
        self.backgroundColor = backgroundColor
        
        self.seperatorView.backgroundColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
    }
    
}
