//
//  NewBeamViewControllerTransitionHandler.swift
//  beam
//
//  Created by Rens Verhoeven on 02/12/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

/// Defines methods that can be called by the NewBeamViewControllerTransitionHandler in order to see if the interactive transition can be started.
protocol NewBeamViewControllerTransitionHandlerDelegate: class {
    /// This method is called to check if an interactive transition can actually start.
    ///
    /// - Parameter handler: The handler that started the interactive transition.
    /// - Returns: If the interactive transition can start.
    func transitionHandlerShouldStartInteractiveTransition(_ handler: NewBeamViewControllerTransitionHandler) -> Bool
    
    /// Called when the interactive transition started. This method should dismiss the view controller animated.
    ///
    /// - Parameter handler: The handler that started the interactive transition.
    func transitionHandlerDidStartInteractiveTransition(_ handler: NewBeamViewControllerTransitionHandler)
    
}

/// The handler that handles a view controller transition that is typical in beam.
/// Retain an instance of this handler and use it as the transition delegate in order to use the transition.
final class NewBeamViewControllerTransitionHandler: NSObject {
    
    /// If the transition should scale down/up the background during the animation.
    public var scaleBackground = true
    
    /// The delegate that called to dismiss the view and if the transition is allowed to begin.
    weak var delegate: NewBeamViewControllerTransitionHandlerDelegate?
    
    /// The animation controller that is used during an interactive transition. If nil while in transition, the transition is not interactive.
    fileprivate var interactiveAnimationController: InteractiveSwipeTransitionAnimationController?
    
    /// An gesture recognizer that should be placed on a UIViewController's view in order to allow a slide from the edge of the screen.
    lazy public fileprivate(set) var screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let gestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(panGestureRecognizerChanged(_:)))
        gestureRecognizer.edges = UIRectEdge.left
        gestureRecognizer.delegate = self
        return gestureRecognizer
    }()
    
    /// An gesture recognizer that should be placed on an element in the top part of the screen. Allows for closing the UIViewController with a slide from the top.
    lazy public fileprivate(set) var topPanGestureRecognizer: UIPanGestureRecognizer = {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerChanged(_:)))
        gestureRecognizer.require(toFail: self.screenEdgePanGestureRecognizer)
        gestureRecognizer.delegate = self
        return gestureRecognizer
    }()
    
    /// Creates a new instance of the handler with the delegate assigned.
    ///
    /// - Parameter delegate: The delegate that should be called to see if the transition is allowed to start.
    init(delegate: NewBeamViewControllerTransitionHandlerDelegate) {
        super.init()
        self.delegate = delegate
    }
    
    @objc private func panGestureRecognizerChanged(_ gestureRecognizer: UIPanGestureRecognizer) {
        let direction: InteractiveSwipeTransitionAnimationController.Direction = gestureRecognizer == self.screenEdgePanGestureRecognizer ? .horizontal : .vertical
        switch gestureRecognizer.state {
        case .began:
            let controller = InteractiveSwipeTransitionAnimationController()
            controller.direction = direction
            controller.isDismissal = true
            self.interactiveAnimationController = controller
            self.delegate?.transitionHandlerDidStartInteractiveTransition(self)
        case .changed:
            guard let interactiveAnimationController = self.interactiveAnimationController, let containerSize = interactiveAnimationController.containerSize else {
                return
            }
            let location = gestureRecognizer.location(in: nil)
            var percent: CGFloat = direction == .horizontal ? (location.x / containerSize.width) : (location.y / containerSize.height)
            percent = min(percent, 0.99)
            percent = max(percent, 0)
            
            self.interactiveAnimationController?.update(percent)
        case .failed, .ended, .cancelled:
            self.interactiveAnimationController?.endInteractiveTransition()
            self.interactiveAnimationController = nil
        default:
            break
            
        }
    }
}

extension NewBeamViewControllerTransitionHandler: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.screenEdgePanGestureRecognizer {
            return true
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.screenEdgePanGestureRecognizer && self.delegate?.transitionHandlerShouldStartInteractiveTransition(self) == false {
            return false
        }
        return true
    }
    
}

extension NewBeamViewControllerTransitionHandler: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard self.shouldUseAnimationController(for: presented) else {
            return nil
        }
        let animationController = InteractiveSwipeTransitionAnimationController()
        animationController.isDismissal = false
        animationController.scaleBackground = self.scaleBackground
        return animationController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard self.shouldUseAnimationController(for: dismissed) else {
            return nil
        }
        guard let interactiveAnimationController = self.interactiveAnimationController else {
            let animationController = InteractiveSwipeTransitionAnimationController()
            animationController.isDismissal = true
            animationController.scaleBackground = self.scaleBackground
            return animationController
        }
        return interactiveAnimationController
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactiveAnimationController
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return BeamPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    private func shouldUseAnimationController(for viewController: UIViewController) -> Bool {
        let traitCollection = AppDelegate.shared.window?.traitCollection ?? viewController.traitCollection
        if let navigationController = viewController as? UINavigationController, let presentation = navigationController.viewControllers.first as? BeamModalPresentation {
            return presentation.preferredModalPresentationStyle == .custom || traitCollection.horizontalSizeClass == .compact
        } else if let presentation = viewController as? BeamModalPresentation {
            return presentation.preferredModalPresentationStyle == .custom || traitCollection.horizontalSizeClass == .compact
        }
        return true
    }
    
}
