//
//  AWKGalleryItemView.h
//  Pods
//
//  Created by Robin Speijer on 08-06-15.
//
//

#import <UIKit/UIKit.h>

#import "AWKGalleryItem.h"

@class AWKGalleryItemDescriptionView;

@protocol AWKGalleryItemDescriptionViewDelegate <NSObject>

@optional

- (BOOL)itemView:(AWKGalleryItemDescriptionView *)footerView shouldInteractWithURL:(NSURL *)URL;

@end

@interface AWKGalleryItemDescriptionView : UIView

@property (nonatomic, strong) id<AWKGalleryItem> item;

@property (nonatomic, weak) id<AWKGalleryItemDescriptionViewDelegate> delegate;

@end
