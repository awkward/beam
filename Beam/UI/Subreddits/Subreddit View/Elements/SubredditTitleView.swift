//
//  SubredditTitleView.swift
//  beam
//
//  Created by Robin Speijer on 21-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

class SubredditTitleView: BeamView {
    
    @IBOutlet fileprivate var contentLabel: UILabel!
    
    class func titleViewWithSubreddit(_ subreddit: Subreddit?) -> SubredditTitleView {
        return UINib(nibName: "SubredditTitleView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! SubredditTitleView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditTitleView.objectsDidChangeInContextNotification(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: AppDelegate.shared.managedObjectContext)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    weak var subreddit: Subreddit? {
        didSet {
            self.contentLabel.attributedText = self.attributedContent
        }
    }
    
    var attributedContent: NSAttributedString? {
        let fullContent = NSMutableAttributedString()
        
        let titleColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        let subtitleColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        
        if let title = self.subreddit?.displayName {
            let titleFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
            
            let titleString = NSAttributedString(string: title, attributes: [NSAttributedStringKey.font: titleFont, NSAttributedStringKey.foregroundColor: titleColor])
            fullContent.append(titleString)
        }
        
        if let multireddit = self.subreddit as? Multireddit {
            fullContent.append(NSAttributedString(string: "\n"))
            
            let subredditCount = multireddit.subreddits?.count ?? 0
            let localizedSubredditsString = subredditCount == 1 ? AWKLocalizedString("subreddit").lowercased() : AWKLocalizedString("subreddits").lowercased()
            var subtitle = "\(subredditCount) \(localizedSubredditsString)"
            let localizedVisibilityString = multireddit.visibility == SubredditVisibility.Public ? AWKLocalizedString("public").capitalized(with: Locale.current) : AWKLocalizedString("private").capitalized(with: Locale.current)
            subtitle += " - \(localizedVisibilityString)"
            
            let subtitleFont = UIFont.systemFont(ofSize: 12)
            
            let subtitleString = NSAttributedString(string: subtitle, attributes: [NSAttributedStringKey.font: subtitleFont, NSAttributedStringKey.foregroundColor: subtitleColor])
            fullContent.append(subtitleString)
        } else if let subreddit = self.subreddit, !subreddit.isPrepopulated && subreddit.visibility == SubredditVisibility.Private {
            fullContent.append(NSAttributedString(string: "\n"))
            let subtitle = subreddit.visibility == SubredditVisibility.Public ? AWKLocalizedString("public").capitalized(with: Locale.current) : AWKLocalizedString("private").capitalized(with: Locale.current)
            
            let subtitleFont = UIFont.systemFont(ofSize: 12)
            let subtitleString = NSAttributedString(string: subtitle, attributes: [NSAttributedStringKey.font: subtitleFont, NSAttributedStringKey.foregroundColor: subtitleColor])
            fullContent.append(subtitleString)
        }
        
        return fullContent
    }
    
    @objc fileprivate func objectsDidChangeInContextNotification(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            let updatedObjects = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? NSSet
            if let subreddit = self.subreddit, updatedObjects?.contains(subreddit) == true && subreddit is Multireddit {
                self.contentLabel.attributedText = self.attributedContent
            }
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.backgroundColor = UIColor.clear
        self.contentLabel.attributedText = self.attributedContent
    }

}
