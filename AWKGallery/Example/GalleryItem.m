//
//  GalleryItem.m
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import "GalleryItem.h"

@implementation GalleryItem

+ (instancetype)itemWithURL:(NSURL *)url {
    if (url) {
        GalleryItem *item = [[GalleryItem alloc] init];
        item.contentURL = url;
        return item;
    }
    return nil;
}

+ (instancetype)itemWithImageURL:(NSURL *)url {
    if (url) {
        GalleryItem *item = [[GalleryItem alloc] init];
        item.contentURL = url;
        item.contentType = AWKGalleryItemContentTypeImage;
        return item;
    }
    return nil;
}

+ (instancetype)itemWithAnimatedImageURL:(NSURL *)url {
    if (url) {
        GalleryItem *item = [[GalleryItem alloc] init];
        item.contentURL = url;
        item.contentType = AWKGalleryItemContentTypeAnimatedImage;
        return item;
    }
    return nil;
}

+ (instancetype)itemWithMovieURL:(NSURL *)url {
    if (url) {
        GalleryItem *item = [[GalleryItem alloc] init];
        item.contentURL = url;
        item.contentType = AWKGalleryItemContentTypeRepeatingMovie;
        return item;
    }
    return nil;
}

- (NSAttributedString *)attributedTitle {
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"Title " attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline], NSLinkAttributeName: [NSURL URLWithString:@"https://github.com/awkward/AWKGallery"], NSForegroundColorAttributeName: [UIColor whiteColor]}]];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"small" attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody], NSForegroundColorAttributeName: [UIColor whiteColor]}]];
    return title;
}

- (NSAttributedString *)attributedSubtitle {
    return [[NSAttributedString alloc] initWithString:@"Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Lorem ipsum dolor sit amet, consectetur adipiscing elit." attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
}

@end
