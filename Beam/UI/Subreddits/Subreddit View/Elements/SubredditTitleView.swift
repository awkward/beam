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

class SubredditTitleView: UIView {
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    
    class func titleViewWithSubreddit(_ subreddit: Subreddit?) -> SubredditTitleView {
        let view = UINib(nibName: "SubredditTitleView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! SubredditTitleView
        view.subreddit = subreddit
        return view
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
            updateContent()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            updateContent()
        }
    }
    
    private func updateContent() {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitleLabel.text == nil || traitCollection.verticalSizeClass == .compact
    }
    
    var title: String {
        subreddit?.displayName ?? AWKLocalizedString("subreddit")
    }
    
    var subtitle: String? {
        if let multireddit = subreddit as? Multireddit {
            let subredditCount = multireddit.subreddits?.count ?? 0
            let localizedSubredditsString = subredditCount == 1 ? AWKLocalizedString("subreddit").lowercased() : AWKLocalizedString("subreddits").lowercased()
            var localizedSubtitle = "\(subredditCount) \(localizedSubredditsString)"
            let localizedVisibilityString = multireddit.visibility == SubredditVisibility.Public ? AWKLocalizedString("public").capitalized(with: Locale.current) : AWKLocalizedString("private").capitalized(with: Locale.current)
            localizedSubtitle += " - \(localizedVisibilityString)"
            return localizedSubtitle
        } else if let subreddit = self.subreddit, !subreddit.isPrepopulated && subreddit.visibility == .Private {
            return subreddit.visibility == .Public ? AWKLocalizedString("public").capitalized(with: Locale.current) : AWKLocalizedString("private").capitalized(with: Locale.current)
        } else {
            return nil
        }
    }
    
    @objc fileprivate func objectsDidChangeInContextNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            let updatedObjects = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? NSSet
            if let subreddit = self.subreddit, updatedObjects?.contains(subreddit) == true && subreddit is Multireddit {
                self.updateContent()
            }
        }
    }

}
