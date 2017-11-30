//
//  AWKGalleryViewController.h
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AWKGalleryItem.h"
#import "AWKGalleryDataSource.h"
#import "AWKGalleryDelegate.h"

/**
 The main view controller for the gallery. You should assign a datasource to fill the content. By default the transitioningDelegate is set to the class itself, because the class has a built in animator for presenting and dismissal. To enable the built in dismissal, implement a delegate.
 */
@interface AWKGalleryViewController : UIViewController

/// @name Content
#pragma mark - Content

/// The datasource of the gallery. This object will be asked about the amount of items, about what the items are and about what the index is of a specific item.
@property (nonatomic, weak, nullable) id<AWKGalleryDataSource> dataSource;

/// The current item that is being displayed by the gallery. You can observe this item to be notified when the user changes the current item by swiping through the gallery.
@property (nonatomic, nullable) id<AWKGalleryItem> currentItem;

@property (nonatomic, readonly, nullable) UIViewController<AWKGalleryItemContent> *currentContentViewController;

/// @name Appearance
#pragma mark - Appearance

/// The amount of points between the gallery items. Default is 10.
@property (nonatomic, assign) CGFloat itemSpacing;

/// Whether or not to include a navigation item title that indicates the position of the displayed item ("3 of 14"). Default: NO
@property (nonatomic, assign) BOOL displaysNavigationItemCount;

/// The delegate of the gallery that will be asked and notified about additional info to enhance the user experience.
@property (nonatomic, weak, nullable) id<AWKGalleryDelegate> delegate;

/// A custom view to be set on the bottom of the gallery, below the image caption. This is nil by default.
@property (nonatomic, strong, nullable) UIView *bottomView;

/// A custom layout guide that contains the length of the bottom views of the gallery. Usefull when implementing custom content view controllers.
@property (nonatomic, readonly, nonnull) id<UILayoutSupport> galleryBottomLayoutGuide;

/// If the gallery is allowed to show the secondary views (navigation bar and bottom content) on viewDidAppear
@property (nonatomic, assign) BOOL shouldAutomaticallyDisplaySecondaryViews;

/// Show or hide the secondary views (navigation bar and bottom content)
- (void)setSecondaryViewsVisible:(BOOL)secondaryViewsVisible animated:(BOOL)animated;

/// Use this action method for a custom navigationItem dismiss button. The delegate will be notified about this call.
- (IBAction)dismissGallery:(nullable id)sender;

/// Reload the order of the viewControllers, for instance when new data is available
- (void)reloadData;

@end
