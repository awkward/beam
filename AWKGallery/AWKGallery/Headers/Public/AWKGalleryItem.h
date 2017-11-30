//
//  AWKGalleryItem.h
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// The content type for a displayed item in the gallery.
typedef NS_ENUM(NSUInteger, AWKGalleryItemContentType) {
    /// If the content type is not known, use this value. The gallery will download the full content (even if it's a movie). When finished, it tries to define a content type by using the MIME type.
    AWKGalleryItemContentTypeUnknown = 0,
    /// A still image that can internally be displayed by using UIImage.
    AWKGalleryItemContentTypeImage,
    /// An animating image (GIF).
    AWKGalleryItemContentTypeAnimatedImage,
    /// A movie that can be played by MPMoviePlayerController.
    AWKGalleryItemContentTypeMovie,
    /// A movie that can be played by MPMovilePlayerController and that will be repeated without controls.
    AWKGalleryItemContentTypeRepeatingMovie
};

/// This protocol defines the information needed for displaying the object in the AWKGalleryViewController.
@protocol AWKGalleryItem <NSObject>

/// @name Content
#pragma mark - Content

/// The URL for the content to be shown.
@property (nonatomic, readonly, nullable) NSURL *contentURL;

/** The content type. You should always have defined a content type other than AWKGalleryItemContentTypeUnknown whenever possible. The gallery adjusts its downloading/rendering mode based on this value.
 
 If you do provide AWKGalleryItemContentTypeUnknown, the app needs to download the whole content to determine what kind of content it is, based on the HTTP Content-Type response header value. If the gallery can not determine the type this way, it tries to create a UIImage from the downloaded data, which is nil if the data is not an image. If so, the gallery will give an failure callback to the delegate and the item will not be visible.
 */
@property (nonatomic, readwrite) AWKGalleryItemContentType contentType;

@optional

/// A placeholder image to use while loading the image. If this image does not exist, the gallery will use a regular activity indicator while loading the image.
@property (nonatomic, readonly, nullable) UIImage *placeholderImage;

/// The data of the fullsize content. If it's an image, return a UIImage. It's being used by the gallery to look up if the fullsize data is already available. The app does not use this fullsize data as placeholder (to prevent slow animations). The gallery fetches the fullsize content if not available. If so, this property will be set back. The contentData will be set back from a background thread.
@property (nonatomic, readwrite, nullable) id contentData;

/// @name Metadata
#pragma mark - Metadata

/// The title for the item, which will be displayed in bold text on the bottom of the gallery.
@property (nonatomic, readonly, nullable) NSAttributedString *attributedTitle;

/// The subtitle for the item, which will be displayed in regular text on the bottom of the gallery.
@property (nonatomic, readonly, nullable) NSAttributedString *attributedSubtitle;

/// The size of the content of the item, this is currently only used for movies
@property (nonatomic, readonly) CGSize contentSize;

@end
