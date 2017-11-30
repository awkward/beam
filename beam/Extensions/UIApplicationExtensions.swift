//
//  UIApplicationExtensions.swift
//  beam
//
//  Created by Rens Verhoeven on 10/11/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

extension UIApplication {
    static private let networkIndicatorQueue = DispatchQueue(label: "com.madeawkward.beam.networkindicator", attributes: [])
    
    static private var networkIndicatorReferences = NSHashTable<AnyObject>(options: NSPointerFunctions.Options.weakMemory)
    
    class func startNetworkActivityIndicator(for reference: AnyObject) {
        self.networkIndicatorQueue.sync { () -> Void in
            self.networkIndicatorReferences.add(reference)
            self.networkIndicatorReferencesChanged()
        }
    }
    
    class func stopNetworkActivityIndicator(for reference: AnyObject) {
        self.networkIndicatorQueue.sync { () -> Void in
            self.networkIndicatorReferences.remove(reference)
            self.networkIndicatorReferencesChanged()
        }
    }
    
    class func networkIndicatorReferencesChanged() {
        DispatchQueue.main.async {
            let isVisible = self.networkIndicatorReferences.count > 0
            if UIApplication.shared.isNetworkActivityIndicatorVisible != isVisible {
                UIApplication.shared.isNetworkActivityIndicatorVisible = isVisible
            }
        }
        
    }
}
