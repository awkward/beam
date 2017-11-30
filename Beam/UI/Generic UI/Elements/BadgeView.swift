//
//  BadgeView.swift
//  beam
//
//  Created by Robin Speijer on 27-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BadgeView: BeamView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.configureTextLabel()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.configureTextLabel()
    }
    
    // MARK: - Properties
    
    fileprivate let textLabel: UILabel = {
        let label = UILabel(frame: CGRect())
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var text: String? {
        get {
            return self.textLabel.text
        }
        set {
            self.textLabel.text = newValue
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 0.5 * self.bounds.height
    }
    
    fileprivate func configureTextLabel() {
        self.addSubview(self.textLabel)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[textLabel]|", options: [], metrics: nil, views: ["textLabel": self.textLabel]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[textLabel]|", options: [], metrics: nil, views: ["textLabel": self.textLabel]))
    }

    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.backgroundColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        self.textLabel.textColor = UIColor.white
    }

}
