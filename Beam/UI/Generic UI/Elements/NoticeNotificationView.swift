//
//  NoticeNotificationView.swift
//  beam
//
//  Created by Rens Verhoeven on 21-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum NoticeNotificationViewType {
    case error
    case information
    case success
}

class NoticeNotificationView: UIControl, NavigationBarNotification {
    
    fileprivate var constrainsAdded: Bool = false
    
    var bottomNotificationConstraint: NSLayoutConstraint?
    
    var dismissDelay: TimeInterval?
    
    var autoDismissalDelay: TimeInterval {
        return self.dismissDelay ?? 3
    }
    
    fileprivate let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 3
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    fileprivate let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "close_small"), for: UIControlState())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.white
        return button
    }()
    
    /**
     To use the message call "presentNoticeNotificationView" on a UINavigationController
     
     - Parameter message: The message in the message view
     - Parameter type: The type of the message, this determnse the colors
     - Parameter dismissDelay: The time to dismiss the message automagicly. Negatice values mean no automagic dismissal

     */
    init(message: String, type: NoticeNotificationViewType = .error, dismissDelay: TimeInterval = 3) {
        super.init(frame: CGRect.zero)
        
        self.addSubview(self.textLabel)
        self.addSubview(self.dismissButton)
        
        self.dismissDelay = dismissDelay
    
        self.textLabel.text = message
        self.textLabel.textColor = self.colorForType(type).textColor
        self.backgroundColor = self.colorForType(type).backgroundColor
        
        self.dismissButton.addTarget(self, action: #selector(NoticeNotificationView.dismissWithSender(_:)), for: .touchUpInside)
        self.addTarget(self, action: #selector(NoticeNotificationView.dismissWithSender(_:)), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        if !self.constrainsAdded {
            let views = ["textLabel": self.textLabel, "dismissButton": self.dismissButton]
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-(30)-[textLabel]-(11)-[dismissButton(==8@1000)]-(11)-|", options: NSLayoutFormatOptions.alignAllTop, metrics: nil, views: views))
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(8)-[textLabel]-(8)-|", options: [], metrics: nil, views: views))
            
        }
    }
    
    func colorForType(_ type: NoticeNotificationViewType) -> (backgroundColor: UIColor, textColor: UIColor) {
        let alpha: CGFloat = 0.95
        switch type {
        case .error:
            return (UIColor(red: 208 / 255.0, green: 46 / 255.0, blue: 56 / 255.0, alpha: alpha), UIColor.white)
        case .information:
            return (UIColor(red: 96 / 255.0, green: 94 / 255.0, blue: 102 / 255.0, alpha: alpha), UIColor.white)
        case .success:
            return (DisplayModeValue(UIColor(red: 0.26, green: 0.19, blue: 0.48, alpha: alpha), darkValue: UIColor(red: 0.46, green: 0.43, blue: 0.6, alpha: alpha)), UIColor.white)
        }
    }
    
    @objc internal func dismissWithSender(_ sender: AnyObject?) {
        self.dismiss()
    }
}

extension UINavigationController {
    
    func presentNoticeNotificationView(_ noticeView: NoticeNotificationView) {
        self.presentNotificationView(noticeView, style: .fullWidth, insets: UIEdgeInsets())
    }
}
