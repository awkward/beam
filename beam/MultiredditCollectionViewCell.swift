//
//  MultiredditCollectionViewCell.swift
//  beam
//
//  Created by Robin Speijer on 06-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

class MultiredditCollectionViewCell: UICollectionViewCell {
    
    var multireddit: Multireddit? {
        didSet {
            self.titleLabel.text = multireddit?.displayName
        }
    }
    
    override var highlighted: Bool {
        didSet {
            self.contentView.backgroundColor = highlighted ? UIColor.lightGrayColor() : UIColor.whiteColor()
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 3
        self.layer.borderWidth = 1.0 / UIScreen.mainScreen().scale
        self.layer.borderColor = UIColor.beamSeparator().CGColor
    }
    
}
