//
//  AWKGalleryViewController-Internal.h
//  Gallery
//
//  Created by Robin Speijer on 30-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AWKGalleryItemContentView, AWKGalleryItemFooterDescriptionView;

@interface AWKGalleryViewController ()

@property (nonatomic, readonly) AWKGalleryItemContentView *currentContentView;
@property (nonatomic, readonly) AWKGalleryItemFooterDescriptionView *footerDescriptionView;

@end