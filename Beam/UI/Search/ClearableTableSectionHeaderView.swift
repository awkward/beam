//
//  ClearableTableSectionHeaderView.swift
//  beam
//
//  Created by Robin Speijer on 15-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class ClearableTableSectionHeaderView: UITableViewHeaderFooterView, DynamicDisplayModeView {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        setupView()
        registerForDisplayModeChangeNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupView()
        registerForDisplayModeChangeNotifications()
    }
    
    deinit {
        unregisterForDisplayModeChangeNotifications()
    }
    
    let clearButton = ClearButton(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
    let titleLabel = UILabel(frame: CGRect.zero)
    
    fileprivate func setupView() {
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        self.titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        self.titleLabel.font = UIFont.systemFont(ofSize: 11)
        self.titleLabel.textColor = UIColor.beamGreyDark()
        
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
    
    @objc func displayModeDidChangeNotification(_ notification: Notification) {
        displayModeDidChangeAnimated(true)
    }
    
    func displayModeDidChange() {
        switch displayMode {
        case .dark:
            titleLabel.textColor = UIColor.beamGrey()
            clearButton.backgroundColor = UIColor.beamGreyLighter()
            clearButton.foregroundColor = UIColor.beamDarkBackgroundColor()
        case .default:
            titleLabel.textColor = UIColor.beamGreyDark()
            clearButton.backgroundColor = UIColor.beamGreyLighter()
            clearButton.foregroundColor = UIColor.systemGroupedBackground
        }
    }

}
