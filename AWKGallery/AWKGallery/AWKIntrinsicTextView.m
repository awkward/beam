//
//  AWKIntrinsicTextView.m
//  Pods
//
//  Created by Robin Speijer on 09-06-15.
//
//

#import "AWKIntrinsicTextView.h"

@implementation AWKIntrinsicTextView

- (void)setPreferredMaxLayoutWidth:(CGFloat)preferredMaxLayoutWidth {
    if (_preferredMaxLayoutWidth != preferredMaxLayoutWidth) {
        _preferredMaxLayoutWidth = preferredMaxLayoutWidth;
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    
    [self invalidateIntrinsicContentSize];
}

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset {
    [super setTextContainerInset:textContainerInset];
    
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize {
    CGFloat constrainedWidth = (self.preferredMaxLayoutWidth != 0) ? (self.preferredMaxLayoutWidth - self.textContainerInset.left - self.textContainerInset.right) : CGRectGetWidth(self.bounds) - self.textContainerInset.left - self.textContainerInset.right;
    CGSize size = [self.attributedText boundingRectWithSize:CGSizeMake(constrainedWidth, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    return CGSizeMake(size.width, size.height + self.textContainerInset.top + self.textContainerInset.bottom + 3);
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

@end
