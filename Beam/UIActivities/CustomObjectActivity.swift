//
//  CustomObjectActivity.swift
//  beam
//
//  Created by Rens Verhoeven on 14/06/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//

import UIKit

class CustomObjectActivity<T: Any>: UIActivity {
    
    var object: T?
    
    func firstObject(in activityItems: [Any]) -> T? {
        return activityItems.compactMap({ (object) -> T? in
            return object as? T
        }).first
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return self.firstObject(in: activityItems) != nil
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        self.object = self.firstObject(in: activityItems)
    }
    
}
