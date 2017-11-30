//
//  UIViewController+EmbeddedLayout.swift
//  beam
//
//  Created by Robin Speijer on 26-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    var contentInset: UIEdgeInsets {
        if let parent = self.parent as? EmbeddingLayoutSupport {
            return parent.embeddedLayout()
        } else if let parent = self.parent {
            return UIEdgeInsets(top: parent.contentInset.top, left: 0, bottom: parent.contentInset.top, right: 0)
        } else {
            // Calculate real origin that is not affected by a transform
            let origin = CGPoint(x: self.view.center.x - 0.5 * self.view.bounds.width, y: self.view.center.y - 0.5 * self.view.bounds.height)
            if self.view.superview?.convert(origin, to: self.view.window).y ?? 0 > 0 || UIApplication.shared.isStatusBarHidden {
                // Modal view is not below statusbar
                return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            } else if let topLayoutGuide = UIApplication.shared.keyWindow?.rootViewController?.topLayoutGuide , topLayoutGuide.length > 0 {
                // If a top layout guide is available and non-zero, use it. It could also be 40 pts high.
                return UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: 0, right: 0)
            } else {
                // Below the statusbar
                return UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
            }
        }
    }
    
    func configureContentLayout() {
        for child in self.childViewControllers {
            if let embeddedView = child as? EmbeddedLayoutSupport {
                embeddedView.updateContentInset()
                embeddedView.resetContentOffset()
            }
        }
        
        if let embeddedSelf = self as? EmbeddedLayoutSupport {
            embeddedSelf.updateContentInset()
            embeddedSelf.resetContentOffset()
        }
    }
    
}

protocol EmbeddingLayoutSupport: class {
    
    func embeddedLayout() -> UIEdgeInsets
    
}

extension EmbeddingLayoutSupport where Self : UIViewController {
    
    func embeddedLayout() -> UIEdgeInsets {
        return self.contentInset
    }
    
}

protocol EmbeddedLayoutSupport: class {
    
    var embeddedScrollView: UIScrollView? { get }
    
    func updateContentInset()
    func resetContentOffset()
    
}

extension EmbeddedLayoutSupport where Self : UIViewController {
    
    var embeddedScrollView: UIScrollView? {
        return self.view as? UIScrollView
    }
    
    func resetContentOffset() {
        self.embeddedScrollView?.contentOffset = CGPoint(x: 0, y: -1 * self.contentInset.top)
    }
    
    func updateContentInset() {
        self.embeddedScrollView?.contentInset = self.contentInset
        self.embeddedScrollView?.scrollIndicatorInsets = self.contentInset
    }
    
}


