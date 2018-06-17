//
//  ManualViewControllerInsets.swift
//  beam
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import UIKit

protocol ManualViewControllerInsets {
    
    func configureInsetsForChildViewControllers()
    
}

extension ManualViewControllerInsets where Self: UIViewController {
    
    func configureInsetsForChildViewControllers() {
        
        for childViewController in self.childViewControllers {
            if let child = childViewController as? UITableViewController {
                configureContentInsetForScrollView(child.tableView)
            } else if let child = childViewController as? UICollectionViewController, let collectionView = child.collectionView {
                configureContentInsetForScrollView(collectionView)
            }
        }
        
    }
    
    fileprivate func configureContentInsetForScrollView(_ scrollView: UIScrollView) {
        let topOffset: CGFloat = self is UIBarPositioningDelegate ? 44.0: 0
        
        scrollView.contentInset = UIEdgeInsets(top: self.topLayoutGuide.length + topOffset, left: 0, bottom: self.bottomLayoutGuide.length, right: 0)
        if scrollView.contentOffset.y <= 0 && !scrollView.isDecelerating && !scrollView.isDragging {
            scrollView.contentOffset = CGPoint(x: 0, y: -1 * scrollView.contentInset.top)
        }
    }
    
}
