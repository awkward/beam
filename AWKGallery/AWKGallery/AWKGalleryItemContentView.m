//
//  AWKGalleryContentView.m
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import "AWKGalleryItemContentView.h"

#import "AWKGalleryItem.h"
#import <AWKGallery/AWKGallery-Swift.h>

@interface AWKGalleryItemContentView ()

@property (nonatomic, strong) AWKProgressView *progressView;

@end

@implementation AWKGalleryItemContentView {
    BOOL activityIndicatorConstraintsAdded;
}

- (instancetype)initWithItem:(id<AWKGalleryItem>)item {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _item = item;
    }
    return self;
}

- (void)updateConstraints {
    if (!activityIndicatorConstraintsAdded && self.progressView) {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_progressView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_progressView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_progressView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_progressView)]];
        activityIndicatorConstraintsAdded = YES;
    }
    
    [super updateConstraints];
}

- (BOOL)shouldZoomAndPan {
    return NO;
}

- (BOOL)prefersFooterViewHidden {
    return NO;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self.progressView intrinsicContentSize];
}

@end
