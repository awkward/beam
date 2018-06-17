//
//  UIView+PrivateView.swift
//  beam
//
//  Created by Robin Speijer on 29-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func privateViewsOfType<T: UIView>(_ subviewType: T.Type, predicate: NSPredicate = NSPredicate(value: true)) -> [T] {
        return UIView.privateViewsOfType(subviewType, inView: self, predicate: predicate)
    }
    
    fileprivate class func privateViewsOfType<T: UIView>(_ subviewType: T.Type, inView view: UIView, predicate: NSPredicate) -> [T] {
        if let view: T = view as? T {
            return [view]
        } else {
            let subviews: [T] = view.subviews.reduce([T](), { (oldArray, new) -> [T] in
                if let subview: T = new as? T, predicate.evaluate(with: subview) {
                    return oldArray + [subview]
                } else {
                    return oldArray + self.privateViewsOfType(subviewType, inView: new, predicate: predicate)
                }
            })
            return subviews
        }
    }
    
}
