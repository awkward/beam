//
//  AWKGalleryLayoutGuide.h
//  beam
//
//  Created by Robin Speijer on 24-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

@import Foundation;
@import UIKit;

@class AWKGalleryViewController;

@interface AWKGalleryLayoutGuide : NSObject <UILayoutSupport>

@property (nonatomic, weak, nullable, readonly) AWKGalleryViewController *galleryViewController;

@property (nonatomic, nullable, readonly) UIView *superview;

- (nonnull instancetype)initWithGalleryViewController:(nonnull AWKGalleryViewController *)gallery;

@end
