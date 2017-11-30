//
//  AWKGalleryImageLoader.h
//  AWKGallery
//
//  Created by Rens Verhoeven on 14-01-16.
//  Copyright © 2016 Robin Speijer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AWKGalleryImageLoader : NSObject

typedef void (^AWKGalleryImageLoaderCompletionHandler)(NSURL *location, NSURLResponse *response, NSError *error);
typedef void (^AWKGalleryImageLoaderProgressHandler)(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);

/**
 *  Downloads the image at the URL and saves it to disk.
 *
 *  @param URL               The URL of the image
 *  @param completionHandler The completionHandler called when the image is done downloading. Called on a seperate thread.
 *  @param progressHandler   The progressHandler called when the image has progressed downloading. Called on the main thread.
 *
 *  @return An instance of of NSURLSessionDataTask
 */
- (NSURLSessionDownloadTask *)downloadImageWithURL:(NSURL *)URL completionHandler:(AWKGalleryImageLoaderCompletionHandler)completionHandler progressHandler:(AWKGalleryImageLoaderProgressHandler)progressHandler;

@end
