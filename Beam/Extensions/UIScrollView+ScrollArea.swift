//
//  ScollAreaExpansion.swift
//  Beam
//
//  Created by Rens Verhoeven on 08/12/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

extension UIScrollView {
    
    /// Places a view to behind a scrollView to improve the scrolling area. This can be used to expand the scrolling area of a TableView that is only displayed on a half of the display
    ///
    /// - Returns: The touched forwarding view that handles the touches. Can be used to change the receiving view later.
    @discardableResult func expandScrollArea() -> TouchesForwardingView? {
        guard let superview = self.superview else {
            return nil
        }
        let touchesView = TouchesForwardingView(receivingView: self)
        superview.insertSubview(touchesView, belowSubview: self)
        
        touchesView.translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[touchesView]|", options: [], metrics: nil, views: ["touchesView": touchesView]))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[touchesView]|", options: [], metrics: nil, views: ["touchesView": touchesView]))
        return touchesView
    }
    
}
