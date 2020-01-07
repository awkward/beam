//
//  URLShareItemProvider.swift
//  Beam
//
//  Created by Rens Verhoeven on 11/10/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import CoreData
import Snoo
import MobileCoreServices

final class URLShareItemProvider: UIActivityItemProvider {

    var object: SyncObject
    var redditUrl: URL
    
    init(object: SyncObject) {
        self.object = object
        
        guard let URL = object.redditUrl ?? URL(string: "https://reddit.com") else {
            fatalError()
        }
        self.redditUrl = URL
        super.init(placeholderItem: URL)
    }

    override var item: Any {
        return self.redditUrl
    }
    
    public override func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return kUTTypeURL as String
    }
    
    override func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.item
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.item
    }
    
}
