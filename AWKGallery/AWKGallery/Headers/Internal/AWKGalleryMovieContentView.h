//
//  AWKGalleryVideoContentView.h
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import "AWKGalleryItemContentView.h"

/// A content view with a built in movie player. Depending on the item's content type, there will be video controls and the video will be repeated. The video will play automatically when viewWillAppear has been called.
@interface AWKGalleryMovieContentView : AWKGalleryItemContentView

@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) UIImage* placeholderImage;

- (void)play;
- (void)pause;

@end
