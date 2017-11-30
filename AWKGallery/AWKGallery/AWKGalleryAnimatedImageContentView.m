//
//  AWKGalleryAnimatedImageContentView.m
//  Gallery
//
//  Created by Robin Speijer on 04-05-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import "AWKGalleryAnimatedImageContentView.h"
#import "AWKGalleryImageContentView-Internal.h"

#import "AWKAnimatedImage.h"

@interface AWKGalleryAnimatedImageContentView ()

@property (nonatomic, strong) AWKAnimatedImageView *imageView;

@end

@implementation AWKGalleryAnimatedImageContentView

@dynamic imageView;

- (void)setAnimatedImage:(AWKAnimatedImage *)animatedImage {
    _animatedImage = animatedImage;
    [self.imageView removeFromSuperview];
    self.imageView = [[AWKAnimatedImageView alloc] init];
    self.imageView.animatedImage = animatedImage;
    self.imageView.frame = self.bounds;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.imageView];
}

- (CGSize)sizeThatFits:(CGSize)size {
    return self.imageView.image.size;
}

@end
