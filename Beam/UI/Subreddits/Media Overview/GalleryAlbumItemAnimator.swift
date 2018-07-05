//
//  GalleryAlbumItemAnimator.swift
//  beam
//
//  Created by Robin Speijer on 22-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import AWKGallery

class GalleryAlbumItemAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var dismissal = false
    
    weak var sourceView: UIImageView?
    
    // MARK: - UIViewControllerAnimatedTransitioning
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if self.dismissal {
            self.animateDismissalTransition(transitionContext)
        } else {
            self.animatePresentationTransition(transitionContext)
        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.dismissal ? 0.15: 0.3
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        
    }
    
    func animatePresentationTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let duration = self.transitionDuration(using: transitionContext)
        
        let animatingView = UIView(frame: container.bounds)
        animatingView.backgroundColor = UIColor.black
        animatingView.alpha = 0
        container.addSubview(animatingView)
        
        let sourceFakeView = UIImageView(frame: sourceView?.frame ?? CGRect())
        sourceFakeView.image = self.sourceView?.image
        sourceFakeView.contentMode = self.sourceView?.contentMode ?? UIViewContentMode.scaleAspectFill
        sourceFakeView.clipsToBounds = true
        sourceFakeView.frame = animatingView.convert(self.sourceView?.frame ?? CGRect(), from: self.sourceView?.superview)
        animatingView.addSubview(sourceFakeView)
    
        UIView.animate(withDuration: duration * 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            
            animatingView.alpha = 1
            sourceFakeView.frame = CGRect(origin: CGPoint(x: 0, y: 64), size: sourceFakeView.frame.size)
            
        }, completion: { (succes: Bool) -> Void in
            
            if let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
                toView.frame = container.bounds
                toView.alpha = 0
                container.addSubview(toView)
                
                UIView.animate(withDuration: duration * 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                    toView.alpha = 1
                }, completion: { (succes: Bool) in
                    animatingView.removeFromSuperview()
                    transitionContext.completeTransition(succes)
                })
            } else {
                animatingView.removeFromSuperview()
                transitionContext.completeTransition(succes)
            }
            
        })
    }
    
    func animateDismissalTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        if let gallery = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? AWKGalleryViewController {

            let duration = self.transitionDuration(using: transitionContext)
            let contentViewController = gallery.currentContentViewController as? AWKGalleryItemContent
            if let contentView = contentViewController?.contentView {
                
                let contentFakeView: UIView? = contentView.snapshotView(afterScreenUpdates: false)
                
                if let contentFakeView = contentFakeView {
                    contentFakeView.frame = container.convert(contentView.frame, from: contentView.superview)
                    container.addSubview(contentFakeView)
                }
                
                let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)
                fromView?.removeFromSuperview()
                
                UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                    if let contentFakeView = contentFakeView {
                        contentFakeView.frame = CGRect(x: contentFakeView.frame.minX, y: container.bounds.midY - 0.5 * contentFakeView.frame.height, width: contentFakeView.frame.width, height: contentFakeView.frame.height)
                        contentFakeView.alpha = 0
                    }
                    
                }, completion: { (succes: Bool) -> Void in
                    contentFakeView?.removeFromSuperview()
                    transitionContext.completeTransition(succes)
                })
                
            }
            
        }
    }

}
