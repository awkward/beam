//
//  AWKGalleryImageContentView.m
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import "AWKGalleryImageContentView.h"
#import "AWKGalleryImageContentView-Internal.h"

#import "AWKGalleryItem.h"

@implementation AWKGalleryImageContentView

@dynamic image;

#pragma mark - Acessors

-(UIImageView *)imageView {
    if (!_imageView) {
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.accessibilityIgnoresInvertColors = true;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self addSubview:imageView];
        self.imageView = imageView;
    }
    
    return _imageView;
}

-(UIImage *)image {
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
}

#pragma mark - Other Methods

-(BOOL)shouldZoomAndPan {
    return YES;
}

#pragma mark - Layout

-(CGSize)sizeThatFits:(CGSize)size {
    return self.imageView.image.size;
}

#pragma mark -

@end
