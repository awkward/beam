//
//  ReportPostActivity.swift
//  beam
//
//  Created by Rens Verhoeven on 23-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Snoo
import UIKit
import MessageUI

class ReportPostActivity: UIActivity {
    
    fileprivate var post: Post?
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.report-post")
    }
    
    override var activityTitle : String? {
        return AWKLocalizedString("post-abuse-activity-title")
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "report_activity_icon")
    }

    override var activityViewController : UIViewController? {
        let storyBoard = UIStoryboard(name: "Report", bundle: nil)
        let navigationController = storyBoard.instantiateInitialViewController() as! BeamNavigationController
        navigationController.useInteractiveDismissal = false
        let reportViewController = navigationController.topViewController as! ReportViewController
        reportViewController.post = self.post
        reportViewController.activity = self
        return navigationController
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if item is Post {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        self.post = activityItems.compactMap({ (object) -> Post? in
            return object as? Post
        }).first
    }
}
