//
//  AWKGalleryDelegate.h
//  Gallery
//
//  Created by Robin Speijer on 29-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The delegate of AWKGalleryViewController. This protocol contains an error handling method, a method to tell the delegate to dismiss the view controller and a method to ask the source view so that it can be used in the animation transition.
@protocol AWKGalleryDelegate <NSObject>

@optional

/// @name Item
#pragma mark - Item

/**
 Tells the delegate that the gallery has failed loading the given item. This might be due to a lack of internet connection or an unsupported format. (optional)
 @param galleryViewController The gallery view controller
 @param item The item that has failed loading
 @param error The error that occured while loading.
 */
- (void)gallery:(AWKGalleryViewController *)galleryViewController failedLoadingItem:(id<AWKGalleryItem>)item withError:(nullable NSError *)error;

/**
 Asks the delegate whether the gallery should use the system behaviour for opening and interacting with links in the title and subtitle of the content.
 
 You can add NSURL objects to the title and subtitle by using the NSLinkAttributeName attribute in its attributed string.
 @param galleryViewController The gallery view controller
 @param item The item of the URL that the user interacts with.
 @param URL The URL of the link that the user interacts with.
 @return A boolean that should indicate whether the system behaviour should be used for opening the URL.
 */
- (BOOL)gallery:(AWKGalleryViewController *)galleryViewController item:(id<AWKGalleryItem>)item shouldInteractWithURL:(NSURL *)URL;

/// @name Transition
#pragma mark - Transition

/**
 Asks the delegate to dismiss the gallery with the given custom content view controller on the foreground. You can change the transitioning delegate of the gallery to deliver a custom view controller transition. If you do so, don't forget to reset the transitioning delegate to the gallery view controller when the dismissal is done. If this method is unimplemented, the gallery:shouldBeDismissedAnimated: method will be called on the delegate.
 @param galleryViewController The gallery view controller
 @param viewController The custom content view controller that is in the gallery at the moment. You can use its view in a custom animator if you want.
 */
- (void)gallery:(AWKGalleryViewController *)galleryViewController shouldBeDismissedWithCustomContentViewController:(UIViewController<AWKGalleryItemContent> *)viewController;

/**
 Asks the delegate to dismiss the gallery, because the user requests so. If not implemented, the gallery will dismiss itself. (optional)
 @param galleryViewController The gallery view controller
 @param animated Whether or not the gallery should be dismissed animated.
 */
- (void)gallery:(AWKGalleryViewController *)galleryViewController shouldBeDismissedAnimated:(BOOL)animated;

/**
 While presenting the gallery, this method asks the delegate for the source view to animate from into the gallery. While dismissing the gallery, the current item animates back into this source view. If not implemented or returning nil, the gallery will use a fade transition.
 @param galleryViewController The gallery view controller
 @param item The item that is currently displayed in the gallery. If the gallery is being presented, this value will be nil.
 @return A view that represents the current item in the gallery. This view will be used in the built in view controller transition. Use a UIImageView if you can, so that the gallery can use the image information from that view for the correct aspect ratio while animating. If nil, the gallery will use a fade transition.
 */
- (nullable UIView *)gallery:(AWKGalleryViewController *)galleryViewController presentationAnimationSourceViewForItem:(id<AWKGalleryItem>)item;

/**
 Notifies the delegate that the user has initiated scrolling to the given item.
 
 To currentItem property has not yet been changed.
 @param galleryViewController The gallery view controller
 @param item The item that will be scrolled to.
 */
- (void)gallery:(AWKGalleryViewController *)galleryViewController willScrollToItem:(id<AWKGalleryItem>)item;

/**
 Notifies the delegate that the user has scrolled from the given item to the current item.
 @param galleryViewController The gallery view controller
 @param item The item that has been scrolled from to the current item (which you can get by using the currentItem property).
 */
- (void)gallery:(AWKGalleryViewController *)galleryViewController didScrollFromItem:(id<AWKGalleryItem>)item;

@end

NS_ASSUME_NONNULL_END
