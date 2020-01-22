//
//  ClearableTableSectionHeaderView.swift
//  beam
//
//  Created by Robin Speijer on 15-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class ClearableTableSectionHeaderView: UITableViewHeaderFooterView, BeamAppearance {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
    }
    
    let clearButton = ClearButton(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
    let titleLabel = UILabel(frame: CGRect.zero)
    
    fileprivate func setupView() {
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        self.titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        self.titleLabel.font = UIFont.systemFont(ofSize: 11)
        self.titleLabel.textColor = .secondaryLabel
        
        self.clearButton.backgroundColor = .beamGreyLighter
        self.clearButton.foregroundColor = .beamContentBackground
        self.clearButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.clearButton)
        
        self.contentView.addConstraint(NSLayoutConstraint(item: self.clearButton, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.titleLabel, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        
        self.contentView.addConstraint(NSLayoutConstraint(item: self.titleLabel, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.contentView, attribute: NSLayoutConstraint.Attribute.bottomMargin, multiplier: 1, constant: 0))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[title]-[clear]-|", options: [], metrics: nil, views: ["title": self.titleLabel, "clear": self.clearButton]))
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let clearButtonHitRect = clearButton.frame.insetBy(dx: -20, dy: -20)
        if clearButtonHitRect.contains(point) {
            return clearButton
        } else {
            clearButton.isSelected = false
        }
        
        return super.hitTest(point, with: event)
    }

}
