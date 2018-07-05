//
//  SubredditPreviewView.swift
//  beam
//
//  Created by Rens Verhoeven on 20/10/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit
import Snoo

final class SubredditPreviewView: BeamView {
    
    var subreddit: Subreddit? {
        didSet {
            guard let displayName = self.subreddit?.displayName, displayName.count > 0 else {
                self.label.text = nil
                self.imageView.image = nil
                self.label.isHidden = false
                return
            }
            if self.subreddit?.identifier == Subreddit.frontpageIdentifier {
                self.imageView.image = #imageLiteral(resourceName: "subreddit_icon_frontpage")
            } else if self.subreddit?.identifier == Subreddit.allIdentifier {
                self.imageView.image = #imageLiteral(resourceName: "subreddit_icon_all")
            } else {
                self.imageView.image = nil
            }
            self.label.isHidden = self.imageView.image != nil
            self.label.text = displayName.substring(to: displayName.index(displayName.startIndex, offsetBy: 1)).uppercased()
        }
    }
    
    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.accessibilityIgnoresInvertColors = true
        return imageView
    }()
    
    lazy private var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.light)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupView() {
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        
        self.addSubview(self.imageView)
        self.addSubview(self.label)
        
        self.setupConstraints()
        self.displayModeDidChange()
    }
    
    private func setupConstraints() {
        let constraints = [
            self.imageView.topAnchor.constraint(equalTo: self.topAnchor),
            self.imageView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.bottomAnchor.constraint(equalTo: self.imageView.bottomAnchor),
            self.rightAnchor.constraint(equalTo: self.imageView.rightAnchor),
            
            self.label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
        
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
    
        self.imageView.backgroundColor = DisplayModeValue(UIColor.beamGreyExtraExtraLight(), darkValue: UIColor.beamGreyDark())
        self.label.textColor = UIColor.beamGreyLight()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        let longestAxis = max(self.bounds.size.width, self.bounds.size.height)
        self.layer.cornerRadius = longestAxis / 2
    }
    
}
