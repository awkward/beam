//
//  InteractiveSwipeTransitionAnimationController.swift
//  beam
//
//  Created by Rens Verhoeven on 22/11/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

public class InteractiveSwipeTransitionAnimationController: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {
    
    public enum Direction {
        
        case horizontal
        
        case vertical
    }
    
    /// If the transition is a dismissal transition.
    public var isDismissal = false
    
    /// The direction the interactive transition should animate in.
    public var direction: Direction = .vertical
    
    /// If the transition should scale down/up the background during the animation.
    public var scaleBackground = true
    
    /// If the alpha of the background view should be adjusted during the animation.
    public var adjustAlpha = true
    
    /// The size of the container if which the transition takes place.
    public var containerSize: CGSize? {
        return self.interactiveTransitionContext?.containerView.bounds.size
    }
    
    /// The animator that is used during the animation.
    private var propertyAnimator: UIViewPropertyAnimator?
    
    /// The transition context that can be used during an interactive transition.
    private var interactiveTransitionContext: UIViewControllerContextTransitioning?
    
    // MARK: - UIPercentDrivenInteractiveTransition
    
    public override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.interactiveTransitionContext = transitionContext
        super.startInteractiveTransition(transitionContext)
    }
    
    public func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if let animator = self.propertyAnimator {
            return animator
        }
        let containerView = transitionContext.containerView
        containerView.backgroundColor = UIAccessibilityIsInvertColorsEnabled() ? .white : .black
        
        // Prepare the view
        // Create animator
        // Return animator
        let animator = UIViewPropertyAnimator(duration: self.transitionDuration(using: transitionContext), timingParameters: UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: CGVector(dx: 0, dy: 0)))
        
        if self.isDismissal {
            if let toViewController = transitionContext.toViewController, let toView = transitionContext.toView, let fromView = transitionContext.fromView {
                containerView.insertSubview(toView, belowSubview: fromView)
                toView.frame = transitionContext.finalFrame(for: toViewController)
                toView.transform = self.beginTransform(for: toView, using: transitionContext)
                toView.alpha = self.adjustAlpha ? 0.5: 1
                
                applyCornerMaskIfNeeded(to: toView)
                applyCornerMaskIfNeeded(to: fromView)
                
                animator.addAnimations {
                    toView.transform = self.endTransform(for: toView, using: transitionContext)
                    toView.alpha = 1
                    fromView.frame = self.modalViewControllerHiddenFrame(for: fromView, using: transitionContext)
                    
                }
                animator.addCompletion({ (_) in
                    toView.transform = .identity
                    toView.frame = transitionContext.finalFrame(for: toViewController)
                    
                    toView.layer.mask = nil
                    fromView.layer.mask = nil
                })
            }
        } else {
            if let toViewController = transitionContext.toViewController, let fromViewController = transitionContext.fromViewController, let toView = transitionContext.toView, let fromView = transitionContext.fromView {
                containerView.insertSubview(toView, aboveSubview: fromView)
                toView.transform = self.beginTransform(for: toView, using: transitionContext)
                toView.frame = transitionContext.finalFrame(for: toViewController)
                toView.frame = self.modalViewControllerHiddenFrame(for: fromView, using: transitionContext)
                
                applyCornerMaskIfNeeded(to: toView)
                applyCornerMaskIfNeeded(to: fromView)
                
                animator.addAnimations {
                    fromView.transform = self.endTransform(for: fromView, using: transitionContext)
                    fromView.alpha = self.adjustAlpha ? 0.5: 1
                    toView.frame = transitionContext.finalFrame(for: toViewController)
                }
                animator.addCompletion({ (_) in
                    fromView.alpha = 1.0
                    fromView.transform = .identity
                    fromView.frame = transitionContext.finalFrame(for: fromViewController)
                    
                    toView.layer.mask = nil
                    fromView.layer.mask = nil
                })
            }
        }
        
        animator.addCompletion { (_) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        self.propertyAnimator = animator
        return animator
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Call animator
        let animator = self.interruptibleAnimator(using: transitionContext)
        animator.startAnimation()
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    public func animationEnded(_ transitionCompleted: Bool) {
        // Kill animator
        self.propertyAnimator = nil
        self.direction = .vertical
    }
    
    // MARK: - Public methods
    
    /// Can be called when the interactive gesture ends, fails or is cancelled. This will either cancel or finish the transition animation based on precentage complete.
    public func endInteractiveTransition() {
        //In order to make the end of the interactive animation seem normal we need to calculate the completionSpeed to slow down the dismiss animation
        if self.percentComplete >= 0.5 {
            self.interactiveTransitionContext?.finishInteractiveTransition()
            self.animate(.end)
        } else {
            self.interactiveTransitionContext?.cancelInteractiveTransition()
            self.animate(.start)
        }
    }
    
    // MARK: - Private methods
    
    private func applyCornerMaskIfNeeded(to view: UIView) {
        let cornerRadius: CGFloat = UIScreen.main.nativeBounds.height == 2436 ? 40: 0
        guard cornerRadius > 0 else {
            return
        }
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = view.layer.bounds
        shapeLayer.path = UIBezierPath(roundedRect: view.layer.bounds, cornerRadius: cornerRadius).cgPath
        view.layer.mask = shapeLayer
    }
    
    fileprivate func beginTransform(for view: UIView, using transitionContext: UIViewControllerContextTransitioning) -> CGAffineTransform {
        guard self.scaleBackground else {
            return CGAffineTransform.identity
        }
        if view == transitionContext.toView && self.isDismissal {
            return self.scaleTransform(using: transitionContext)
        }
        return CGAffineTransform.identity
    }
    
    fileprivate func endTransform(for view: UIView, using transitionContext: UIViewControllerContextTransitioning) -> CGAffineTransform {
        guard self.scaleBackground else {
            return CGAffineTransform.identity
        }
        if !self.isDismissal && view == transitionContext.fromView {
            return self.scaleTransform(using: transitionContext)
        }
        return CGAffineTransform.identity
    }
    
    fileprivate func scaleTransform(using transitionContext: UIViewControllerContextTransitioning) -> CGAffineTransform {
        let inset: CGFloat = 18.0
        let frame = transitionContext.containerView.bounds
        let scaledHeight = frame.height - (inset * 2)
        let scale = scaledHeight / frame.height
        return CGAffineTransform(scaleX: scale, y: scale)
    }
    
    private func modalViewControllerHiddenFrame(for view: UIView, using transitionContext: UIViewControllerContextTransitioning) -> CGRect {
        let containerView = transitionContext.containerView
        var rect = view.frame
        switch self.direction {
        case .horizontal:
            rect.origin.x = containerView.bounds.width
        case .vertical:
            rect.origin.y = containerView.bounds.height
        }
        return rect
    }
    
    private func animate(_ toPosition: UIViewAnimatingPosition) {
        // Reverse the transition animator if we are returning to the start position
        propertyAnimator?.isReversed = (toPosition == .start)
        
        // Start or continue the transition animator (if it was previously paused)
        if propertyAnimator?.state == .inactive {
            propertyAnimator?.startAnimation()
        } else {
            // Calculate the duration factor for which to continue the animation.
            // This has been chosen to match the duration of the property animator created above
            
            propertyAnimator?.continueAnimation(withTimingParameters: UISpringTimingParameters(dampingRatio: 1), durationFactor: 0.5)
        }
    }
}
