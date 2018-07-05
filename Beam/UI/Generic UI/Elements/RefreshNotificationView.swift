//
//  RefreshNotificationView.swift
//  beam
//
//  Created by Rens Verhoeven on 30-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class RefreshNotificationView: BeamControl, NavigationBarNotification {
    
    //NavigationBarNotification variables
    var bottomNotificationConstraint: NSLayoutConstraint?
    var autoDismissalDelay: TimeInterval = 0
    var displayView: UIView?
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "refresh_pill"))
        imageView.tintColor = UIColor.white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center
        return imageView
    }()
    let textLabel: UILabel = {
        let label = UILabel()
        label.text = AWKLocalizedString("stream-updated")
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.medium)
        return label
    }()
    
    let presentationEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 12)
    
    var dismissOnTap: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupViews()
    }
    
    func setupViews() {
        self.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        
        self.addSubview(self.iconImageView)
        self.addSubview(self.textLabel)
        let views = ["icon": self.iconImageView, "text": self.textLabel]
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[icon]-(10)-[text]-|", options: [], metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[icon]-|", options: [], metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[text]-|", options: [], metrics: nil, views: views))
        
        self.addTarget(self, action: #selector(RefreshNotificationView.hasBeenTapped(_:)), for: .touchUpInside)
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let backgroundColor: UIColor = self.displayMode == .default ? UIColor.beamColor() : UIColor.beamPurpleLight()
        self.backgroundColor = backgroundColor
        self.textLabel.backgroundColor = backgroundColor
        self.iconImageView.backgroundColor = backgroundColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = true
    }
    
    internal func dismissWithSender(_ sender: AnyObject?) {
        self.dismiss()
    }
    
    @objc func hasBeenTapped(_ sender: AnyObject?) {
        if self.dismissOnTap {
            self.dismiss()
        }
    }
}
