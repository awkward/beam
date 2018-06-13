//
//  AWKGalleryItemExpandedDescriptionView.m
//  Pods
//
//  Created by Robin Speijer on 08-06-15.
//
//

#import "AWKGalleryItemExpandedDescriptionView.h"

#import "AWKIntrinsicTextView.h"

@interface AWKGalleryItemExpandedDescriptionView () <UITextViewDelegate>

@property (nonatomic, strong) AWKIntrinsicTextView *contentView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

void AWKGalleryItemExpandedDescriptionViewInitialize(AWKGalleryItemExpandedDescriptionView *view);

@end

@implementation AWKGalleryItemExpandedDescriptionView {
    BOOL constraintsAdded;
}

@dynamic delegate;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        AWKGalleryItemExpandedDescriptionViewInitialize(self);
    }
    return self;
}

void AWKGalleryItemExpandedDescriptionViewInitialize(AWKGalleryItemExpandedDescriptionView *view) {
    view.layoutMargins = UIEdgeInsetsMake(64, 12, 0, 12);
    view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7f];
    view.userInteractionEnabled = YES;
    view.contentView = ({
        AWKIntrinsicTextView *textView = [[AWKIntrinsicTextView alloc] initWithFrame:CGRectZero];
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        textView.textContainer.lineFragmentPadding = 0;
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.selectable = YES;
        textView.editable = NO;
        textView.backgroundColor = [UIColor clearColor];
        textView.preferredMaxLayoutWidth = CGRectGetWidth(view.bounds) - view.layoutMargins.left - view.layoutMargins.right;
        textView.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        textView;
    });
    view.contentView.delegate = view;
    [view addSubview:view.contentView];

    view.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:view action:@selector(viewDidTap:)];
    [view addGestureRecognizer:view.tapGestureRecognizer];
    
    [view setNeedsUpdateConstraints];
}

- (void)updateConstraints {
 
    if (!constraintsAdded) {
        constraintsAdded = YES;
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_contentView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_contentView)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeTopMargin multiplier:1 constant:0]];
    }
    
    [super updateConstraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds) - self.layoutMargins.left - self.layoutMargins.right;
}

- (void)viewDidTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    if ([self.delegate respondsToSelector:@selector(tappedExpandedItemView:)]) {
        [self.delegate tappedExpandedItemView:self];
    }
}

- (void)setItem:(id<AWKGalleryItem>)item {
    [super setItem:item];
    
    self.contentView.attributedText = self.attributedContent;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
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

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([self.delegate respondsToSelector:@selector(itemView:shouldInteractWithURL:)]) {
        return [self.delegate itemView:self shouldInteractWithURL:URL];
    }
    return YES;
}

@end
