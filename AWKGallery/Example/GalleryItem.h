//
//  GalleryItem.h
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AWKGalleryItem.h"

@interface GalleryItem : NSObject <AWKGalleryItem>

+ (instancetype)itemWithURL:(NSURL *)url;
+ (instancetype)itemWithImageURL:(NSURL *)url;
+ (instancetype)itemWithAnimatedImageURL:(NSURL *)url;
+ (instancetype)itemWithMovieURL:(NSURL *)url;

@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic, assign) AWKGalleryItemContentType contentType;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) UIImage *placeholderImage;

@end
