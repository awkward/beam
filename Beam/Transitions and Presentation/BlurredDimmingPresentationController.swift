//
//  BlurredDimmingPresentationController.swift
//  beam
//
//  Created by Rens Verhoeven on 03-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class BlurredDimmingPresentationController: UIPresentationController {
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(frame: CGRect())
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        self.blurView.frame = self.containerView?.bounds ?? CGRect()

        if let presentedView = self.presentedView {
            self.containerView?.addSubview(self.blurView)
            self.containerView?.addSubview(presentedView)
        }
        
        let transitionCoordinator = self.presentingViewController.transitionCoordinator
        transitionCoordinator?.animate(alongsideTransition: { (_) -> Void in
            self.blurView.effect = UIBlurEffect(style: UIBlurEffectStyle.light)
            }, completion: nil)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            self.blurView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin() {
        let transitionCoordinator = self.presentingViewController.transitionCoordinator
        transitionCoordinator?.animate(alongsideTransition: { (_) -> Void in
            self.blurView.effect = nil
            }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            self.blurView.removeFromSuperview()
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        // As the StoreViewController is a collection view controller, the background should be clear. Therefore the frame of the presented view controller can just be fullscreen. Whenever this changes in the future, a custom frame should be set here.
        return super.frameOfPresentedViewInContainerView
    }
    
    override var shouldPresentInFullscreen: Bool {
        return true
    }
    
    override var shouldRemovePresentersView: Bool {
        return false
    }

}
