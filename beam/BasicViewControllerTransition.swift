//
//  BasicViewControllerTransition.swift
//  beam
//
//  Created by Rens Verhoeven on 03-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum BasicViewControllerTransitionStyle {
    case coverVertically
    case fade
    
    func endAlpha() -> CGFloat {
        if self == .fade {
            return 1
        }
        return 1
    }
    
    func beginAlpha() -> CGFloat {
        if self == .fade {
            return 0
        }
        return 1
    }
    
    func beginFrameForContext(_ transitionContext: UIViewControllerContextTransitioning, viewController: UIViewController) -> CGRect {
        let container = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: viewController)
        if self == .fade {
            return finalFrame
        }
        return CGRect(origin: CGPoint(x: container.bounds.minX, y: container.bounds.height), size: finalFrame.size)
    }
    
    func endFrameForContext(_ transitionContext: UIViewControllerContextTransitioning, viewController: UIViewController) -> CGRect {
        let finalFrame = transitionContext.finalFrame(for: viewController)
        return finalFrame
    }
}

/// An animated transition to accomodate simple view controller transitions. You can choose between the BasicViewControllerTransitionStyle enum values, which are currenly only very basic transitions. This is because you need to use a custom animator in order to use a UIPresentationController subclass, to add for example a dimming view.
class BasicViewControllerTransition: NSObject, UIViewControllerAnimatedTransitioning {

    var animationStyle: BasicViewControllerTransitionStyle = .coverVertically
    var isDismissal = false
    
    // MARK: - UIViewControllerAnimatedTransitioning
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if self.isDismissal {
            self.animateDismissalTransition(transitionContext)
        } else {
            self.animatePresentationTransition(transitionContext)
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        
    }
    
    // MARK: - Animation
    
    fileprivate func animateDismissalTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        if let dismissedView = transitionContext.view(forKey: UITransitionContextViewKey.from), let dismissedViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) {

            let duration = self.transitionDuration(using: transitionContext)
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                //Dismiss is the animation in reverse
                dismissedView.alpha = self.animationStyle.beginAlpha()
                dismissedView.frame = self.animationStyle.beginFrameForContext(transitionContext, viewController: dismissedViewController)
            }, completion: { (success: Bool) -> Void in
                transitionContext.completeTransition(success)
            })
            
        }
    }
    
    fileprivate func animatePresentationTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        if let presentedView = transitionContext.view(forKey: UITransitionContextViewKey.to), let presentedViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) {
            
            presentedView.frame = self.animationStyle.beginFrameForContext(transitionContext, viewController: presentedViewController)
            let duration = self.transitionDuration(using: transitionContext)
            
            if presentedView.superview == nil {
                transitionContext.containerView.addSubview(presentedView)
            }
            
            presentedView.alpha = self.animationStyle.beginAlpha()
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                presentedView.alpha = self.animationStyle.endAlpha()
                presentedView.frame = self.animationStyle.endFrameForContext(transitionContext, viewController: presentedViewController)
            }, completion: { (success: Bool) -> Void in
                transitionContext.completeTransition(success)
            })
        }
    }
    
}
