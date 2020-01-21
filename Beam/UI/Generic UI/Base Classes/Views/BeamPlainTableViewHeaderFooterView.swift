//
//  BeamPlainTableViewHeaderFooterView.swift
//  beam
//
//  Created by Robin Speijer on 16-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BeamPlainTableViewHeaderFooterView: UITableViewHeaderFooterView, BeamAppearance {
    
    var titleFont: UIFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold) {
        didSet {
            setupStyle()
        }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupStyle()
    }
    
    private func setupStyle() {
        contentView.backgroundColor = .beamPlainSectionHeader
        textLabel?.textColor = .beamGreyLight
        textLabel?.font = self.titleFont
    }
    
    //This fixes a bug where the font is never changed
    override func layoutSubviews() {
        super.layoutSubviews()
        setupStyle()
    }

}
