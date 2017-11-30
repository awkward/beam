//
//  BeamViewControllerTransition.swift
//  beam
//
//  Created by Robin Speijer on 19-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum BeamViewControllerTransitionDirection {
    case horizontal
    case vertical
}

protocol BeamViewControllerTransitionDelegate: class {
    
    func modalViewControllerTransition(_ transition: BeamViewControllerTransition, shouldInteractivelyDismissInDirection: BeamViewControllerTransitionDirection)
    
    func modalViewControllerTransition(_ transition: BeamViewControllerTransition, didCompleteTransition: Bool)
    
    func modalViewControllerTransitionShouldStartInteractiveSidePanTransition(_ transition: BeamViewControllerTransition) -> Bool
    
}

extension BeamViewControllerTransitionDelegate {
    
    func modalViewControllerTransitionShouldStartInteractiveSidePanTransition(_ transition: BeamViewControllerTransition) -> Bool {
        return true
    }
}

extension UIViewControllerContextTransitioning {
    
    var fromViewController: UIViewController? {
        return self.viewController(forKey: UITransitionContextViewControllerKey.from)
    }
    
    var fromView: UIView? {
        return self.view(forKey: UITransitionContextViewKey.from) ?? self.fromViewController?.view
    }
    
    var toViewController: UIViewController? {
        return self.viewController(forKey: UITransitionContextViewControllerKey.to)
    }
    
    var toView: UIView? {
        return self.view(forKey: UITransitionContextViewKey.to) ?? self.toViewController?.view
    }
    
}

/// The animator to use for the interactive modal beam view controller presentation. Set the isDismissal property, set the delegate and add the gesture recognizers to the appropiate views in the modal view controller.
class BeamViewControllerTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate {
    
    /// Whether the animator is a dismissal or a presentation
    var isDimissal = false
    fileprivate var interactive = false
    fileprivate weak var transitionContext: UIViewControllerContextTransitioning?
    
    var adjustAlphaDuringTransition = true
    
    var includesScaling = true
    
    var shouldStartInteractiveTransition: Bool {
        return self.sidePanDismissalGestureRecognizer.state == .began || self.topPanDismissalGestureRecognizer.state == .began
    }
    
    /// The delegate to ask the presenter to dismiss the modal view controller. When this is called, dismiss the modal view controller if you want. An interactive transition will be triggered.
    weak var delegate: BeamViewControllerTransitionDelegate?
    
    fileprivate let percentCompleteMinimum: CGFloat = 0.3
    
    fileprivate var direction = BeamViewControllerTransitionDirection.vertical
    
    /// The gesture recognizer that is used for the left screen edge dismissal. Add it to the presenting view controller view.
    lazy var sidePanDismissalGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let recognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(BeamViewControllerTransition.panSideGestureRecognizer(_:)))
        recognizer.edges = UIRectEdge.left
        recognizer.delegate = self
        return recognizer
    }()
    
    /// The gesture recognizer that is used for the top to bottom dismissal. Add it to the presenting view controller view where you want to trigger the dismissal (for example a navigation bar).
    lazy var topPanDismissalGestureRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(BeamViewControllerTransition.panTopGestureRecognizer(_:)))
        recognizer.require(toFail: self.sidePanDismissalGestureRecognizer)
        recognizer.delegate = self
        return recognizer
    }()
    
    fileprivate func presentingTransform(with context: UIViewControllerContextTransitioning, dismissal: Bool) -> CGAffineTransform {
        guard self.includesScaling else {
            return CGAffineTransform.identity
        }
        
        let inset: CGFloat = 18.0
        let frame = self.transitionContext?.containerView.bounds ?? UIScreen.main.bounds
        let scaledHeight = frame.height - (inset * 2)
        let scale = scaledHeight / frame.height
        return CGAffineTransform(scaleX: scale, y: scale)
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        if self.isDimissal {
            animateDismissalTransition(transitionContext)
        } else {
            animatePresentationTransition(transitionContext)
        }
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        if self.isDimissal, let toView = self.transitionContext?.toView {
            if self.includesScaling {
                toView.transform = CGAffineTransform.identity
            }
            if self.adjustAlphaDuringTransition {
                toView.alpha = 1.0
            }
        } else if !self.isDimissal, let fromView = self.transitionContext?.fromView {
            if self.includesScaling {
                fromView.transform = CGAffineTransform.identity
            }
            if self.adjustAlphaDuringTransition {
                fromView.alpha = 1.0
            }
        }
        
        self.interactive = false
        self.direction = .vertical
        self.delegate?.modalViewControllerTransition(self, didCompleteTransition: transitionCompleted)
    }
    
    //Duration of 0.01 is speed to work around a bug where "completionHandler:" isn't called
    var interactiveTransitionDuration: TimeInterval = 0.00001
    //Duration of the transition
    var normalTransitionDuration: TimeInterval = 0.5
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if self.interactive == true {
            return self.interactiveTransitionDuration
        }
        return self.normalTransitionDuration
    }
    
    // MARK: - Presentation
    
    fileprivate func animatePresentationTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        if let fromView = transitionContext.fromView, let toView = transitionContext.toView, let toViewController = transitionContext.toViewController {

            containerView.addSubview(toView)
            toView.frame = self.modalViewControllerHiddenFrameInContext(transitionContext)
            fromView.transform = CGAffineTransform.identity
            
            let duration = self.transitionDuration(using: transitionContext)
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
                if self.adjustAlphaDuringTransition == true {
                    fromView.alpha = 0.5
                }
                if self.includesScaling {
                    fromView.transform = self.presentingTransform(with: transitionContext, dismissal: false)
                }
                toView.frame = transitionContext.finalFrame(for: toViewController)
            }, completion: { (success: Bool) -> Void in
                transitionContext.completeTransition(success)
                if self.includesScaling {
                    fromView.transform = CGAffineTransform.identity
                }
                if self.adjustAlphaDuringTransition {
                    fromView.alpha = 1.0
                }
            })
            
        }
        
    }
    
    // MARK: - Dismissal
    
    fileprivate func animateDismissalTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        
        configurePreDismissalStateInContext(transitionContext)

        let duration = self.transitionDuration(using: transitionContext)
        if self.interactive {
            
            UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: { () -> Void in
                self.configurePostDismissalStateInContext(transitionContext)
            }, completion: { (succes: Bool) -> Void in
                self.finishDismissalAnimationCompletionInContext(transitionContext)
            })

        } else {
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                    self.configurePostDismissalStateInContext(transitionContext)
                }, completion: { (succes: Bool) -> Void in
                    self.finishDismissalAnimationCompletionInContext(transitionContext)
            })
        }
        
    }
    
    /// Set all properties of the view controller views right before the animation takes place of the dismissal.
    fileprivate func configurePreDismissalStateInContext(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        if let fromView = transitionContext.fromView, let toView = transitionContext.toView  {
            if toView.superview == nil {
                containerView.insertSubview(toView, belowSubview: fromView)
            }
            if let viewController = transitionContext.toViewController {
                toView.frame = transitionContext.finalFrame(for: viewController)
            }
            if self.includesScaling {
                toView.transform = self.presentingTransform(with: transitionContext, dismissal: true)
            }
            if self.adjustAlphaDuringTransition {
                toView.alpha = 0.5
            }
        }
    }
    
    /// Set all the properties of the view controller views right within the animation block of a dismissal.
    fileprivate func configurePostDismissalStateInContext(_ transitionContext: UIViewControllerContextTransitioning) {
        
        if let fromView = transitionContext.fromView, let toView = transitionContext.toView {
            if self.adjustAlphaDuringTransition == true {
                toView.alpha = 1.0
            }
            toView.transform = CGAffineTransform.identity
            fromView.frame = self.modalViewControllerHiddenFrameInContext(transitionContext)
        }

    }

    /// Executes the completing steps of a dismissal animation (to be executed in the animation completion handler).
    fileprivate func finishDismissalAnimationCompletionInContext(_ transitionContext: UIViewControllerContextTransitioning) {
        if let toView = transitionContext.toView , transitionContext.transitionWasCancelled && self.adjustAlphaDuringTransition == true {
            toView.alpha = 0.5
        }
        
        if let fromView = transitionContext.fromView , fromView.superview != nil && !transitionContext.transitionWasCancelled {
            fromView.removeFromSuperview()
        }

        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

    }
    
    // MARK: - Animation helpers
    
    fileprivate func modalViewControllerHiddenFrameInContext(_ transitionContext: UIViewControllerContextTransitioning) -> CGRect {
        
        let containerBounds = transitionContext.containerView.bounds 
        let verticalFrame = CGRect(x: containerBounds.minX, y: containerBounds.maxY, width: containerBounds.width, height: containerBounds.height)
        
        switch self.direction {
        case .horizontal:
            if let fromView = transitionContext.fromView , self.isDimissal {
                return CGRect(x: containerBounds.width, y: fromView.frame.minY, width: fromView.frame.width, height: fromView.frame.height)
            } else {
                return CGRect(x: containerBounds.width, y: containerBounds.minY, width: containerBounds.width, height: containerBounds.height)
            }
        case .vertical:
            return verticalFrame
        }
    }
    
    // MARK: - Dismissal pan
    
    func panSideGestureRecognizer(_ sender: AnyObject) {
        guard let gestureRecognizer  = sender as? UIScreenEdgePanGestureRecognizer else {
            return
        }
        
        switch gestureRecognizer.state {
            
        case .began:
            self.interactive = true
            self.direction = .horizontal
            self.delegate?.modalViewControllerTransition(self, shouldInteractivelyDismissInDirection: BeamViewControllerTransitionDirection.horizontal)
        case .changed:
            self.updateInteractiveTransitionWithGestureRecognizer(gestureRecognizer)
        case .ended:
            fallthrough case .failed:
            fallthrough case .cancelled:
                self.updateInteractiveTransitionWithGestureRecognizer(gestureRecognizer)
                self.endInteractiveTransition()
        default:
            break
        }
        
    }
    
    func panTopGestureRecognizer(_ sender: AnyObject) {
        guard let gestureRecognizer  = sender as? UIPanGestureRecognizer else {
            return
        }
        
        switch gestureRecognizer.state {
            
        case .began:
            self.interactive = true
            self.direction = .vertical
            self.delegate?.modalViewControllerTransition(self, shouldInteractivelyDismissInDirection: BeamViewControllerTransitionDirection.vertical)
        case .changed:
                self.updateInteractiveTransitionWithGestureRecognizer(gestureRecognizer)
            
        
        case .ended:
        fallthrough case .failed:
        fallthrough case .cancelled:
                self.updateInteractiveTransitionWithGestureRecognizer(gestureRecognizer)
                self.endInteractiveTransition()
        default:
            break
        }
        
    }
    
    fileprivate func updateInteractiveTransitionWithGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        let location = gestureRecognizer.location(in: nil)
        var percent: CGFloat = 0.0
        if self.direction == .horizontal {
            percent = location.x / UIApplication.shared.keyWindow!.bounds.width
        } else {
            percent = location.y / UIApplication.shared.keyWindow!.bounds.height
        }
        percent = min(percent, 0.99)
        percent = max(percent, 0)
        self.update(percent)
    }
    
    fileprivate func endInteractiveTransition() {
        //In order to make the end of the interactive animation seem normal we need to calculate the completionSpeed to slow down the dismiss animation
        self.completionSpeed = CGFloat(self.interactiveTransitionDuration/self.normalTransitionDuration)
        if self.percentComplete >= self.percentCompleteMinimum {
            self.finish()
        } else {
            self.cancel()
        }
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.sidePanDismissalGestureRecognizer {
            return true
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.sidePanDismissalGestureRecognizer && self.delegate?.modalViewControllerTransitionShouldStartInteractiveSidePanTransition(self) == false {
            return false
        }
        return true
    }
    

}
