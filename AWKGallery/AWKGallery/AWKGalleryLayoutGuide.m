//
//  AWKGalleryLayoutGuide.m
//  beam
//
//  Created by Robin Speijer on 24-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

#import "AWKGalleryLayoutGuide.h"

#import "AWKGalleryViewController.h"
#import "AWKGalleryViewController-Internal.h"
#import "AWKGalleryItemFooterDescriptionView.h"

@implementation AWKGalleryLayoutGuide

- (instancetype)initWithGalleryViewController:(AWKGalleryViewController *)gallery {
    self = [super init];
    if (self) {
        _galleryViewController = gallery;
    }
    return self;
}

- (UIView *)superview {
    return self.galleryViewController.view;
}

- (CGFloat)length {
    return CGRectGetHeight(self.galleryViewController.view.bounds) - CGRectGetMinY(self.galleryViewController.footerDescriptionView.frame);
}

- (NSLayoutYAxisAnchor *)bottomAnchor {
    return self.galleryViewController.view.bottomAnchor;
}

- (NSLayoutYAxisAnchor *)topAnchor {
    return self.galleryViewController.footerDescriptionView.topAnchor;
}

@end
