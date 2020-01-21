//
//  SubredditListTableViewCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 14-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

class SubredditListTableViewCell: BeamTableViewCell {
    
    var subreddit: Subreddit? {
        didSet {
            if self.subreddit == nil {
                self.textLabel?.font = UIFont.systemFont(ofSize: 17)
            } else {
                self.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
            }
            self.textLabel?.attributedText = self.attributedTitle
            self.textLabel?.numberOfLines = self.subreddit == nil ? 1 : 2
        }
    }
    
    lazy var subscribersCountNumberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.locale = Locale.current
        numberFormatter.usesGroupingSeparator = true
        return numberFormatter
    }()
    
    fileprivate var attributedTitle: NSAttributedString {
        let title = NSMutableAttributedString()
        
        if let titleString = self.subreddit?.displayName {
            let titleColor = self.userInterfaceStyle == .dark ? UIColor.white: UIColor.black
            title.append(NSAttributedString(string: titleString, attributes: [NSAttributedString.Key.foregroundColor: titleColor]))
        }
        
        let subtitleColor = AppearanceValue(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.8)
        
        var subtitle: String?
        if self.subreddit?.identifier == Subreddit.frontpageIdentifier {
            subtitle = "\n\(AWKLocalizedString("frontpage-description"))"
        } else if self.subreddit?.identifier == Subreddit.allIdentifier {
            subtitle = "\n\(AWKLocalizedString("all-description"))"
        } else if self.subreddit?.isUserAuthorized != true {
            subtitle = "\n\(AWKLocalizedString("private"))"
        } else if let subscribers = self.subreddit?.subscribers {
            subtitle = "\n\(self.subscribersCountNumberFormatter.string(from: subscribers) ?? "0") \(AWKLocalizedString("subscribers"))"
        }
        if let subtitle = subtitle {
            title.append(NSAttributedString(string: subtitle, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13), NSAttributedString.Key.foregroundColor: subtitleColor]))
        }
        
        return title
    }

    override func appearanceDidChange() {
        super.appearanceDidChange()
        self.textLabel?.attributedText = self.attributedTitle
    }

}
