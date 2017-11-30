//
//  AWKGalleryItemZoomView.h
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AWKGalleryItemZoomView : UIScrollView

@property (nonatomic, readonly, getter=isZoomedOut) BOOL zoomedOut;

@property (nonatomic, strong) UIView *contentView;
- (void)resetContentViewPosition;

+ (CGRect)destinationFrameForSourceFrame:(CGRect)viewBounds inZoomViewBounds:(CGRect)bounds;
+ (CGFloat)minimumScaleForContentBounds:(CGRect)viewBounds inZoomViewBounds:(CGRect)bounds;

@end
