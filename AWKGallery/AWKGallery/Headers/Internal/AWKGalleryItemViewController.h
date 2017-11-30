//
//  AWKGalleryItemViewController.h
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AWKGalleryItem.h"
#import "AWKGalleryItemContent.h"
#import "AWKGalleryItemContentView.h"

@class AWKGalleryImageLoader;

@interface AWKGalleryItemViewController : UIViewController<AWKGalleryItemContent>

- (instancetype _Nonnull)initWithItem:(id<AWKGalleryItem> _Nullable)item NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, getter=isDismissableBySwiping) BOOL dismissableBySwiping;

#pragma mark - AWKGalleryItemContent
@property (nonatomic, strong, nullable) id<AWKGalleryItem> item;
@property (nonatomic) BOOL visible;
@property (nonatomic, readonly, nonnull) AWKGalleryItemContentView *contentView;

@property (nonatomic, strong, nullable) UIImage *placeholderImage;

#pragma mark - Gallery specifics
@property (nonatomic, nullable, copy) void (^onFetchFailure)(id<AWKGalleryItem> _Nullable item, NSError  * _Nullable error);
@property (nonatomic, readonly, getter=isLoading) BOOL loading;
@property (nonatomic, nullable, weak) AWKGalleryImageLoader *imageLoader;

@end
