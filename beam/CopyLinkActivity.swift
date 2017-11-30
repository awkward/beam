//
//  CopyLinkActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 25-07-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class CopyLinkActivity: UIActivity {

    fileprivate var URL: Foundation.URL?
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.copy-link")
    }
    
    override var activityTitle : String? {
        return NSLocalizedString("copy-link-activity-title", comment: "Title of the copy link share activity on comments")
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "copy_link_activity_icon")
    }
    
    override func perform() {
        super.perform()
        UIPasteboard.general.url = self.URL
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if item is Foundation.URL {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if item is Foundation.URL {
                self.URL = item as? Foundation.URL
            }
        }
    }
    
}
