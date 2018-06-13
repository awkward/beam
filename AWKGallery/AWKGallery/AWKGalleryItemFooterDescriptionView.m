//
//  AWKGalleryFooterView.m
//  Gallery
//
//  Created by Robin Speijer on 04-05-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import "AWKGalleryItemFooterDescriptionView.h"
#import "AWKIntrinsicTextView.h"

@interface AWKGalleryItemFooterDescriptionView () <UITextViewDelegate>

@property (nonatomic) AWKIntrinsicTextView *textView;
@property (nonatomic) UIButton *expandButton;

@property (nonatomic) NSLayoutConstraint *textBottomConstraint;
@property (nonatomic) NSLayoutConstraint *textHeightConstraint;

@end

@implementation AWKGalleryItemFooterDescriptionView {
    BOOL constraintsAdded;
}

@dynamic delegate;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupFooterView];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupFooterView];
    }
    return self;
}

- (void)setupFooterView {
    
    self.clipsToBounds = YES;
    self.layoutMargins = UIEdgeInsetsMake(0, 12, 0, 12);
    
    self.textView = ({
        AWKIntrinsicTextView *view = [[AWKIntrinsicTextView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor clearColor];
        view.font = [UIFont systemFontOfSize:17];
        view.textColor = [UIColor whiteColor];
        view.textAlignment = NSTextAlignmentLeft;
        view.selectable = YES;
        view.editable = NO;
        view.scrollEnabled = YES;
        view.dataDetectorTypes = UIDataDetectorTypeLink;
        view.textContainer.lineFragmentPadding = 0;
        view.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
        view.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        view.scrollEnabled = NO;
        view.clipsToBounds = YES;
        [view setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        view;
    });
    self.textView.delegate = self;
    [self addSubview:self.textView];
    
    self.expandButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tintColor = [UIColor whiteColor];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.clipsToBounds = YES;
        button.alpha = 0.8f;
        [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        button;
    });
    
    if ([self.delegate respondsToSelector:@selector(expansionButtonTitleInFooterView:)]) {
        [self.expandButton setTitle:[self.delegate expansionButtonTitleInFooterView:self] forState:UIControlStateNormal];
    } else {
        [self.expandButton setTitle:@"Read more..." forState:UIControlStateNormal];
    }
    
    [self.expandButton addTarget:self action:@selector(expandButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.expandButton];
    
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    if (!constraintsAdded) {
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_textView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_textView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_textView][_expandButton(22)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_textView, _expandButton)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_expandButton]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_expandButton)]];
        
        self.textBottomConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:0];
        self.textBottomConstraint.priority = 999;
        [self addConstraint:self.textBottomConstraint];
        
        NSLayoutConstraint *buttonBottomConstraint = [NSLayoutConstraint constraintWithItem:self.expandButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:0];
        buttonBottomConstraint.priority = 500;
        [self addConstraint:buttonBottomConstraint];
        
        self.textHeightConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
        [self.textView addConstraint:self.textHeightConstraint];
        
        constraintsAdded = YES;
    }
    
    self.textHeightConstraint.constant = [self maximumTextHeight];
    self.textBottomConstraint.active = ![self shouldShowExpansion];
    
    [super updateConstraints];
}

- (CGFloat)maximumTextHeight {
    return 0.2 * CGRectGetHeight([UIScreen mainScreen].bounds) - 52;
}

- (CGSize)textFittingSize {
    CGSize constrainingSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width - self.layoutMargins.left - self.layoutMargins.right, CGFLOAT_MAX);
    return [self.textView sizeThatFits:constrainingSize];
}

- (BOOL)shouldShowExpansion {
    return [self textFittingSize].height > [self maximumTextHeight];
}

- (CGSize)intrinsicContentSize {
    if ([self shouldShowExpansion]) {
        return CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds), [self maximumTextHeight] + ([self shouldShowExpansion] ? 22 : 0));
    } else {
        CGSize textFittingSize = [self textFittingSize];
        CGSize textSize = CGSizeMake(textFittingSize.width, MIN(textFittingSize.height, self.textHeightConstraint.constant));
        CGSize size = CGSizeMake(textSize.width + self.layoutMargins.left + self.layoutMargins.right, textSize.height + self.layoutMargins.top + self.layoutMargins.bottom + ([self shouldShowExpansion] ? 22 : 0));
        return size;
    }
}

- (void)setItem:(id<AWKGalleryItem>)item {
    [super setItem:item];
    
    self.textView.attributedText = self.attributedContent;
    self.hidden = [self attributedItemTitle].length == 0 && [self attributedItemSubtitle].length == 0;
    
    [self setNeedsUpdateConstraints];
    [self invalidateIntrinsicContentSize];

}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.textView setPreferredMaxLayoutWidth:CGRectGetWidth(self.textView.bounds)];
}

- (NSAttributedString *)attributedItemTitle {
    if ([self.item respondsToSelector:@selector(attributedTitle)]) {
        return [self.item attributedTitle];
    }
    return nil;
}

- (NSAttributedString *)attributedItemSubtitle {
    if ([self.item respondsToSelector:@selector(attributedSubtitle)]) {
        return [self.item attributedSubtitle];
    }
    return nil;
}

- (NSAttributedString *)attributedContent {
    NSMutableArray *elements = [[NSMutableArray alloc] init];
    
    if ([self.item respondsToSelector:@selector(attributedTitle)]) {
        NSAttributedString *title = [self.item attributedTitle];
        if (title) [elements addObject:title];
    }
    
    if ([self.item respondsToSelector:@selector(attributedSubtitle)]) {
        NSAttributedString *subtitle = [self.item attributedSubtitle];
        if (subtitle) [elements addObject:subtitle];
    }
    
    if (elements.count >= 2) {
        [elements insertObject:[[NSAttributedString alloc] initWithString:@"\n"] atIndex:1];
    }
    
    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] init];
    [elements enumerateObjectsUsingBlock:^(NSAttributedString *obj, NSUInteger idx, BOOL *stop) {
        [contentString appendAttributedString:obj];
    }];
    return contentString;
}

#pragma mark - UITextViewDelegate

- (void)expandButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tappedExpansionButtonForFooterView:)]) {
        [self.delegate tappedExpansionButtonForFooterView:self];
    }
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([URL.scheme isEqualToString:@"AWKGallery"] && [URL.host isEqualToString:@"expand"]) {
        if ([self.delegate respondsToSelector:@selector(tappedExpansionButtonForFooterView:)]) {
            [self.delegate tappedExpansionButtonForFooterView:self];
        }
        return NO;
    } else if ([self.delegate respondsToSelector:@selector(itemView:shouldInteractWithURL:)]) {
        return [self.delegate itemView:self shouldInteractWithURL:URL];
    } else {
        return YES;
    }
}

@end
