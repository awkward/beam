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
        
        var redditUrl: URL!
        if let objectRedditUrl = self.object.redditUrl {
            redditUrl = objectRedditUrl
        } else {
            redditUrl = URL(string: "https://reddit.com")!
        }
        self.redditUrl = redditUrl
        super.init(placeholderItem: redditUrl)
    }

    override var item: Any {
        return self.redditUrl
    }
    
    public override func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String {
        return kUTTypeURL as String
    }
    
    override func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.item
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        return self.item
    }
    
}
