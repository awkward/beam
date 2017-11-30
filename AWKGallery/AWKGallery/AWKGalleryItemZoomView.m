//
//  AWKGalleryItemZoomView.m
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import "AWKGalleryItemZoomView.h"
#import "AWKGalleryItemContentView.h"

@interface AWKGalleryItemZoomView () <UIScrollViewDelegate>
{
    CGPoint _pointToCenterAfterResize;
    CGFloat _scaleToRestoreAfterResize;
}

@end

@implementation AWKGalleryItemZoomView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTappedView:)];
        tapGestureRecognizer.numberOfTapsRequired = 2;
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    return self;
}

- (void)doubleTappedView:(UITapGestureRecognizer *)gestureRecognizer {
    CGFloat scale = (self.zoomScale > self.minimumZoomScale) ? self.minimumZoomScale : self.maximumZoomScale;
    
    [self setNeedsLayout];
    [UIView animateWithDuration:0.3f animations:^{
        self.zoomScale = scale;
        [self layoutIfNeeded];
    }];
}

- (void)setContentView:(UIView *)view {
    if (_contentView != view) {
        [_contentView removeFromSuperview];
        _contentView = view;
        
        self.zoomScale = 1.0;
        view.frame = [self.class destinationFrameForSourceFrame:view.bounds inZoomViewBounds:self.bounds];
        [self addSubview:view];
        [self setMaxMinZoomScalesForCurrentBounds];
    }
}

- (void)resetContentViewPosition {
    self.zoomScale = 1.0;
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
    self.contentView.frame = [self.class destinationFrameForSourceFrame:self.contentView.bounds inZoomViewBounds:self.bounds];
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];

}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    BOOL superShouldBegin = [super gestureRecognizerShouldBegin:gestureRecognizer];
    
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint location = [gestureRecognizer locationInView:self.contentView];
        //If the location of the pan gesture recognizer is not inside of the content view we allow it to begin
        if (CGRectContainsPoint(self.contentView.bounds, location) == NO) {
            return YES;
        }
        if (superShouldBegin && self.zoomScale == self.minimumZoomScale) {
            return self.contentOffset.y > [self minimumContentOffset].y && self.contentOffset.y < [self maximumContentOffset].y;
        }
    }
    
    return superShouldBegin;
}

+ (CGRect)destinationFrameForSourceFrame:(CGRect)viewBounds inZoomViewBounds:(CGRect)bounds {
    CGSize boundsSize = bounds.size;
    
    if (viewBounds.size.height == 0 || viewBounds.size.width == 0) {
        return bounds;
    }
    
    CGFloat sourceRatio = viewBounds.size.width / viewBounds.size.height;
    CGFloat boundsRatio = bounds.size.width / bounds.size.height;
    
    if (sourceRatio < boundsRatio) {
        // Constrained to height
        CGFloat newHeight = boundsSize.height;
        CGFloat newWidth = newHeight * sourceRatio;
        return CGRectMake(0.5 * (boundsSize.width - newWidth), 0, newWidth, newHeight);
    } else {
        // Constrained to width
        CGFloat newWidth = boundsSize.width;
        CGFloat newHeight = newWidth / sourceRatio;
        return CGRectMake(0, 0.5 * (boundsSize.height - newHeight), newWidth, newHeight);
    }
}

+ (CGFloat)minimumScaleForContentBounds:(CGRect)viewBounds inZoomViewBounds:(CGRect)bounds {
    CGSize boundsSize = bounds.size;
    
    if (viewBounds.size.width > 0 && viewBounds.size.height > 0) {
        
        // calculate min/max zoomscale
        CGFloat xScale = boundsSize.width  / viewBounds.size.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / viewBounds.size.height;   // the scale needed to perfectly fit the image height-wise
        
        return MIN(xScale, yScale);
    }
    return 1;
}

- (void)setFrame:(CGRect)frame
{
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    if (sizeChanging) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging) {
        [self recoverFromResizing];
    }
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    
    if (([self.contentView isKindOfClass:[AWKGalleryItemContentView class]] && ((AWKGalleryItemContentView *)self.contentView).shouldZoomAndPan) && self.contentView.bounds.size.width > 0 && self.contentView.bounds.size.height > 0) {
        CGFloat minScale = [self.class minimumScaleForContentBounds:self.contentView.bounds inZoomViewBounds:self.bounds];
        
        // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
        // maximum zoom scale to 0.5.
        CGFloat maxScale = minScale*2;
        
        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if (minScale > maxScale) {
            minScale = maxScale;
        }
        
        self.maximumZoomScale = maxScale;
        self.minimumZoomScale = minScale;
    } else {
        self.minimumZoomScale = 1;
        self.maximumZoomScale = 1;
    }
}

- (void)prepareToResize
{
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _pointToCenterAfterResize = [self convertPoint:boundsCenter toView:_contentView];
    
    _scaleToRestoreAfterResize = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (_scaleToRestoreAfterResize <= self.minimumZoomScale + FLT_EPSILON)
        _scaleToRestoreAfterResize = 0;
}

- (void)recoverFromResizing
{
    [self setMaxMinZoomScalesForCurrentBounds];
    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
    self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:_pointToCenterAfterResize fromView:_contentView];
    
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    
    CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
    offset.x = MAX(minOffset.x, realMaxOffset);
    
    realMaxOffset = MIN(maxOffset.y, offset.y);
    offset.y = MAX(minOffset.y, realMaxOffset);
    
    self.contentOffset = offset;
    [self resetContentViewPosition];
}

- (CGPoint)maximumContentOffset
{
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset
{
    return CGPointZero;
}

- (BOOL)isZoomedOut {
    return self.zoomScale <= self.minimumZoomScale;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _contentView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    CGFloat offsetX = MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0);
    CGFloat offsetY = MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0);
    
    self.contentView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

@end
