//
//  MultiredditSubTableViewCell.swift
//  beam
//
//  Created by Robin Speijer on 06-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class MultiredditSubTableViewCell: BeamTableViewCell {
    
    var indexPath: IndexPath?
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var editButton: UIButton!
    
    var editButtonTappedHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.editButton.addTarget(self, action: #selector(MultiredditSubTableViewCell.editButtonTapped(_:)), for: .touchUpInside)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.indexPath = nil
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.editButton.frame.insetBy(dx: -10, dy: -10).contains(point) {
            return self.editButton
        }
        return super.hitTest(point, with: event)
    }
    
    @objc func editButtonTapped(_ sender: UIButton) {
        self.editButtonTappedHandler?()
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.titleLabel.textColor = DisplayModeValue(UIColor.beamGreyExtraDark(), darkValue: UIColor.white)
    }

}
