//
//  AWKGalleryContentView.h
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AWKGallery.h"

@class AWKGalleryItemContentView;

@protocol AWKGalleryItemContentViewDelegate <NSObject>

@optional
- (void)didChangeBoundsForGalleryContentView:(AWKGalleryItemContentView *)view;

@end

/**
 The Gallery Item Content View displays the content itself to be displayed in a gallery item. The bounds will change if the content changes.
 */
@interface AWKGalleryItemContentView : UIView

- (instancetype)initWithItem:(id<AWKGalleryItem>)item;
@property (nonatomic, strong, readonly) id<AWKGalleryItem> item;

@property (nonatomic, readonly) BOOL shouldZoomAndPan;
@property (nonatomic, readonly) BOOL prefersFooterViewHidden;

@end
