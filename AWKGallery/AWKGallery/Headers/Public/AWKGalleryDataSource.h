//
//  AWKGalleryDataSource.h
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWKGalleryItem.h"
#import "AWKGalleryItemContent.h"

NS_ASSUME_NONNULL_BEGIN

@class AWKGalleryViewController;

/// A protocol in order to ask the datasource of the gallery about the content.
@protocol AWKGalleryDataSource <NSObject>

/**
 Asks the number of items in the gallery.
 @param galleryViewController The gallery view controller
 @return The amount of items in the gallery. Should be more than 0, otherwise you should have not presented the gallery.
 */
- (NSInteger)numberOfItemsInGallery:(AWKGalleryViewController *)galleryViewController;

/**
 The item to display in the gallery at the given index.
 @param galleryViewController The gallery view controller
 @param index The index of the item to return.
 @return The item to display at this position in the gallery.
 */
- (id<AWKGalleryItem>)gallery:(AWKGalleryViewController *)galleryViewController itemAtIndex:(NSUInteger)index;

/**
 Asks the datasource about the position of the given item in the gallery.
 @param galleryViewController The gallery view controller
 @param item The item to get the index in the gallery for.
 @return An index in the gallery. Should be less then the number of items in the gallery.
 */
- (NSInteger)gallery:(AWKGalleryViewController *)galleryViewController indexOfItem:(id<AWKGalleryItem>)item;

@optional

/**
 A custom view controller to be used as content in the gallery.
 @param galleryViewController The gallery view controller.
 @param item The item to get the custom content for.
 @return A custom view controller to be displayed as content in the gallery. It must conform to AWKGalleryItemContent. If you return nil, the gallery will display the default gallery content.
 */
- (nullable UIViewController<AWKGalleryItemContent> *)gallery:(AWKGalleryViewController *)galleryViewController contentViewControllerForItem:(id<AWKGalleryItem>)item;

@end

NS_ASSUME_NONNULL_END
