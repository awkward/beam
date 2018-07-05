//
//  CopyLinkActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 25-07-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

final class CopyLinkActivity: CustomObjectActivity<URL> {

    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.copy-link")
    }
    
    override var activityTitle: String? {
        return NSLocalizedString("copy-link-activity-title", comment: "Title of the copy link share activity on comments")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "copy_link_activity_icon")
    }
    
    override func perform() {
        super.perform()
        UIPasteboard.general.url = self.object
    }
    
}
