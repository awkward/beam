//
//  AWKGalleryAnimator.m
//  Gallery
//
//  Created by Robin Speijer on 30-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import "AWKGalleryAnimator.h"

#import "AWKGalleryItemZoomView.h"
#import "AWKGalleryViewController.h"
#import "AWKGalleryItemContentView.h"
#import "AWKGalleryViewController-Internal.h"

#import <AWKGallery/AWKGallery-Swift.h>

@implementation AWKGalleryAnimator

#pragma mark - Animated

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (!self.isDismissal) {
        [self animatePresentationTransition:transitionContext];
    } else {
        [self animateDismissalTransition:transitionContext];
    }
}

- (void)animatePresentationTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    CGFloat animationDuration = [self transitionDuration:transitionContext];
    
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = [transitionContext containerView];
    
    toViewController.view.hidden = YES;
    toViewController.view.frame = container.bounds;
    [container addSubview:toViewController.view];
    
    UIView *toFakeView = [[UIView alloc] initWithFrame:container.bounds];
    toFakeView.backgroundColor = [UIColor galleryBackgroundColor];
    toFakeView.alpha = 0;
    toFakeView.accessibilityIgnoresInvertColors = true;
    [container addSubview:toFakeView];

    UIImageView *fromFakeView = [[UIImageView alloc] initWithFrame:CGRectZero];
    fromFakeView.contentMode = UIViewContentModeScaleAspectFill;
    fromFakeView.accessibilityIgnoresInvertColors = true;
    fromFakeView.frame = [container convertRect:self.sourceView.frame fromView:self.sourceView.superview];
    [container addSubview:fromFakeView];
    
    if ([self.sourceView isKindOfClass:[UIImageView class]] && ((UIImageView *)self.sourceView).image != nil) {
        fromFakeView.image = [(UIImageView *)self.sourceView image];
    } else if (self.sourceView) {
        UIGraphicsBeginImageContextWithOptions(self.sourceView.bounds.size, NO, 0);
        [self.sourceView drawViewHierarchyInRect:self.sourceView.bounds afterScreenUpdates:NO];
        UIImage *fromFakeImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        fromFakeView.image = fromFakeImage;
    } else {
        fromFakeView.frame = container.bounds;
    }

    [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        toFakeView.alpha = 1;
        if (fromFakeView && self.sourceView) {
            CGRect imageRect = CGRectMake(0, 0, fromFakeView.image.size.width, fromFakeView.image.size.height);
            fromFakeView.frame = [AWKGalleryItemZoomView destinationFrameForSourceFrame:imageRect inZoomViewBounds:container.bounds];
        }
    } completion:^(BOOL finished) {
        toViewController.view.hidden = NO;

        [toFakeView removeFromSuperview];
        [fromFakeView removeFromSuperview];
        
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)animateDismissalTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    CGFloat animationDuration = [self transitionDuration:transitionContext];
    
    AWKGalleryViewController *fromViewController = (AWKGalleryViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    UIView *blackBackground = [[UIView alloc] initWithFrame:containerView.bounds];
    blackBackground.backgroundColor = [UIColor galleryBackgroundColor];
    blackBackground.accessibilityIgnoresInvertColors = true;
    [containerView insertSubview:blackBackground belowSubview:fromViewController.view];
    
    AWKGalleryItemContentView *fromContentView = fromViewController.currentContentView;
    UIView *fromFakeView = [fromContentView snapshotViewAfterScreenUpdates:NO];
    fromFakeView.frame = [fromContentView convertRect:fromFakeView.frame toView:containerView];
    fromFakeView.contentMode = UIViewContentModeScaleAspectFit;
    fromFakeView.accessibilityIgnoresInvertColors = true;
    [containerView insertSubview:fromFakeView belowSubview:fromViewController.view];
    
    BOOL originalHidden = self.sourceView.hidden;
    self.sourceView.hidden = NO;
    [self.sourceView layoutIfNeeded];
    UIView *sourceFakeView = [self.sourceView snapshotViewAfterScreenUpdates:YES];
    sourceFakeView.accessibilityIgnoresInvertColors = true;
    if (self.sourceView) {
        self.sourceView.hidden = originalHidden;
        sourceFakeView.frame = fromFakeView.frame;
        sourceFakeView.alpha = 0;
        [containerView insertSubview:sourceFakeView belowSubview:fromFakeView];
    }
    
    [fromViewController.view removeFromSuperview];
    
    [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{
        blackBackground.alpha = 0;
        if (self.sourceView) {
            fromFakeView.frame = [containerView convertRect:self.sourceView.frame fromView:self.sourceView.superview];
            sourceFakeView.frame = [containerView convertRect:self.sourceView.frame fromView:self.sourceView.superview];
        }
        fromFakeView.alpha = 0;
        sourceFakeView.alpha = 1;
    } completion:^(BOOL finished) {
        [blackBackground removeFromSuperview];
        [fromFakeView removeFromSuperview];
        [sourceFakeView removeFromSuperview];
        [transitionContext completeTransition:finished];
    }];
}

- (void)animationEnded:(BOOL)transitionCompleted {
    if (self.onAnimationEndHandler) {
        self.onAnimationEndHandler(transitionCompleted);
    }
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3f ;
}

@end
