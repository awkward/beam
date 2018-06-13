//
//  UIViewControllerContextTransitioningExtensions.swift
//  beam
//
//  Created by Rens Verhoeven on 28/12/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

extension UIViewControllerContextTransitioning {

    /// The view controller that is animated from, on dismissal this is likely the front most view controller.
    var fromViewController: UIViewController? {
        return self.viewController(forKey: UITransitionContextViewControllerKey.from)
    }
    
    /// The view that is animated from, on dismissal this is likely the front most view.
    var fromView: UIView? {
        return self.view(forKey: UITransitionContextViewKey.from) ?? self.fromViewController?.view
    }
    
    /// The view controller that is animated to, on dismissal this is likely the original view controller "below" the current view controller.
    var toViewController: UIViewController? {
        return self.viewController(forKey: UITransitionContextViewControllerKey.to)
    }
    
    /// The view that is animated to, on dismissal this is likely the original view "below" the current view.
    var toView: UIView? {
        return self.view(forKey: UITransitionContextViewKey.to) ?? self.toViewController?.view
    }
    
}
