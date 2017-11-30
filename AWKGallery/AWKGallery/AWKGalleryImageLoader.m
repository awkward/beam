//
//  AWKGalleryImageLoader.m
//  AWKGallery
//
//  Created by Rens Verhoeven on 14-01-16.
//  Copyright © 2016 Robin Speijer. All rights reserved.
//

#import "AWKGalleryImageLoader.h"

@interface AWKGalleryImageLoader () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSMutableDictionary *progressHandlers;
@property (strong, nonatomic) NSMutableDictionary *completionHandlers;

@end

@implementation AWKGalleryImageLoader

- (id)init {
    self = [super init];
    if(self) {
        self.progressHandlers = [NSMutableDictionary new];
        self.completionHandlers = [NSMutableDictionary new];
    }
    return self;
}

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    }
    return _session;
}

- (NSURLSessionDownloadTask *)downloadImageWithURL:(NSURL *)URL completionHandler:(AWKGalleryImageLoaderCompletionHandler)completionHandler progressHandler:(AWKGalleryImageLoaderProgressHandler)progressHandler {
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:request];
    if (completionHandler) {
        [self.completionHandlers setObject:[completionHandler copy] forKey:task];
    }
    if (progressHandler) {
        [self.progressHandlers setObject:[progressHandler copy] forKey:task];
    }
    [task resume];
    return task;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    AWKGalleryImageLoaderCompletionHandler completionHandler = [self.completionHandlers objectForKey:downloadTask];
    if (completionHandler) {
        completionHandler(location, downloadTask.response, nil);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.completionHandlers removeObjectForKey:downloadTask];
        [self.progressHandlers removeObjectForKey:downloadTask];
    });
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    AWKGalleryImageLoaderProgressHandler progressHandler = [self.progressHandlers objectForKey:downloadTask];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (progressHandler) {
            progressHandler(totalBytesWritten, totalBytesExpectedToWrite);
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        AWKGalleryImageLoaderCompletionHandler completionHandler = [self.completionHandlers objectForKey:task];
        if (error) {
            if (completionHandler) {
                completionHandler(nil, task.response, error);
            }
            
            [self.completionHandlers removeObjectForKey:task];
            [self.progressHandlers removeObjectForKey:task];
            
        }
    });
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSURLSessionDownloadTask *task in self.completionHandlers.allKeys) {
            AWKGalleryImageLoaderCompletionHandler completionHandler = [self.completionHandlers objectForKey:task];
            if (completionHandler) {
                completionHandler(nil, task.response, error);
            }
        }
        [self.completionHandlers removeAllObjects];
        [self.progressHandlers removeAllObjects];
    });
}

@end
