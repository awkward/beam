//
//  AWKGalleryFooterView.h
//  Gallery
//
//  Created by Robin Speijer on 04-05-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AWKGalleryItemDescriptionView.h"
#import "AWKGalleryItem.h"

@class AWKGalleryItemFooterDescriptionView;

@protocol AWKGalleryItemFooterDescriptionViewDelegate <AWKGalleryItemDescriptionViewDelegate>

@optional

- (void)tappedExpansionButtonForFooterView:(AWKGalleryItemFooterDescriptionView *)footerView;
- (NSString *)expansionButtonTitleInFooterView:(AWKGalleryItemFooterDescriptionView *)footerView;

@end

@interface AWKGalleryItemFooterDescriptionView : AWKGalleryItemDescriptionView

@property (nonatomic, weak) id<AWKGalleryItemFooterDescriptionViewDelegate> delegate;

@property (nonatomic, readonly) NSAttributedString *attributedContent;

@end
