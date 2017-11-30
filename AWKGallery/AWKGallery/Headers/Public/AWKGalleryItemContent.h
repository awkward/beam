//
//  AWKGalleryItemContent.h
//  AWKGallery
//
//  Created by Robin Speijer on 09-10-15.
//  Copyright © 2015 Robin Speijer. All rights reserved.
//

/**
 The protocol to implement in view controllers to display them in the gallery.
 */
@protocol AWKGalleryItemContent <NSObject>

/// The item of the gallery content.
@property (nonatomic, readwrite, nullable) id<AWKGalleryItem> item;

/// A boolean indicating whether this content view controller is visible on screen or not. Will be set by the gallery.
@property (nonatomic, readwrite) BOOL visible;

/// The view that represents the actual content within the view controller. This will be used for animated transitions.
@property (nonatomic, readonly, nonnull) UIView *contentView;

@end