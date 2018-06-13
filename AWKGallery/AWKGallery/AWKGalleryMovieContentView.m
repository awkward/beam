//
//  AWKGalleryVideoContentView.m
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "AWKGalleryMovieContentView.h"
#import "AWKGalleryItemZoomView.h"

static void * AWKGalleryMovieContentViewKVOContext = &AWKGalleryMovieContentViewKVOContext;

@interface AWKGalleryMovieContentView ()

@property (nonatomic, readonly) BOOL repeatingMovie;
@property (nonatomic, weak) NSTimer* readyTimer;

@property (nonatomic, strong) AVPlayerViewController* playerController;
@property (nonatomic, strong) UIImageView* placeholderView;

@property (nonatomic, strong) AVPlayerLooper *playerLooper;

- (void)playerControllerDidFinishPlaying:(NSNotification*)notification;
- (void)hidePlaceholderIfReady;

@end
@implementation AWKGalleryMovieContentView

@dynamic placeholderImage;

#pragma mark Accessors

-(BOOL)repeatingMovie {
    return (self.item.contentType == AWKGalleryItemContentTypeRepeatingMovie);
}

- (void)setVideoURL:(NSURL *)videoURL {
    if (![_videoURL isEqual:videoURL] && videoURL) {
        _videoURL = videoURL;
        
        [self.playerController.player removeObserver:self forKeyPath:@"status" context:AWKGalleryMovieContentViewKVOContext];
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:_videoURL];
        
        if (self.repeatingMovie && [NSProcessInfo processInfo].operatingSystemVersion.majorVersion >= 10) {
            AVQueuePlayer *player = [AVQueuePlayer playerWithPlayerItem:playerItem];
            self.playerLooper = [AVPlayerLooper playerLooperWithPlayer:player templateItem:playerItem];
            self.playerController.player = player;
        } else {
            self.playerController.player = [AVPlayer playerWithPlayerItem:playerItem];
        }
        
        [self.playerController.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:AWKGalleryMovieContentViewKVOContext];
    } else if (!videoURL) {
        [self.playerController.player removeObserver:self forKeyPath:@"status" context:AWKGalleryMovieContentViewKVOContext];
        self.playerController.player = nil;
        self.playerLooper = nil;
    }
}

-(UIImage*)placeholderImage {
    return self.placeholderView.image;
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage {
    if (!self.placeholderView) {
        self.placeholderView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.placeholderView.contentMode = UIViewContentModeScaleAspectFit;
        self.placeholderView.accessibilityIgnoresInvertColors = true;
        [self addSubview:self.placeholderView];
    }
    
    self.placeholderView.image = placeholderImage;
}

- (void)setReadyTimer:(NSTimer *)readyTimer {
    if (![_readyTimer isEqual:readyTimer]) {
        [_readyTimer invalidate];
        _readyTimer = readyTimer;
    }
}

#pragma mark - Initialization

-(instancetype)initWithItem:(id<AWKGalleryItem>)item {
    self = [super initWithItem:item];
    if (self) {
        self.playerController = [AVPlayerViewController new];
        self.playerController.showsPlaybackControls = !self.repeatingMovie;
        self.playerController.view.accessibilityIgnoresInvertColors = true;
        
        if (!self.repeatingMovie || [NSProcessInfo processInfo].operatingSystemVersion.majorVersion < 10) {
            self.playerController.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        }
        [self addSubview:self.playerController.view];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerControllerDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Explicitily nil out so that observers are cleaned up
    self.videoURL = nil;
}

#pragma mark - Playback

- (void)playerControllerDidFinishPlaying:(NSNotification*)notification {
    if (self.repeatingMovie && [NSProcessInfo processInfo].operatingSystemVersion.majorVersion < 10 && [notification.object isEqual:self.playerController.player.currentItem]) {
        //Somehow AVPlayer thinks both the begining and the end are CMTimeZero. That's why it's best to use 0,001 second to make sure it starts at the first frame
        [self.playerController.player.currentItem seekToTime:CMTimeMake(1, 1000) completionHandler:nil];
        [self.playerController.player play];
    }
}

- (void)hidePlaceholderIfReady {
    if (self.playerController.readyForDisplay) {
        self.readyTimer = nil;
        self.placeholderView.hidden = YES;
    }
    
    [self setNeedsLayout];
}

- (void)play {
    [self.playerController.player play];
    
    // This makes it possible to 'observe' readyForDisplay to avoid blank frames
    self.readyTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(hidePlaceholderIfReady) userInfo:nil repeats:YES];
    [self hidePlaceholderIfReady];
}

- (void)pause {
    [self.playerController.player pause];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AWKGalleryMovieContentViewKVOContext) {
        [self setNeedsLayout];
        
        if (self.playerController.player.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer failed to load movie: %@", self.playerController.player.error);
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Screenshot

- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates {
    CGRect videoFrame = self.playerController.videoBounds;
    
    UIView* (^animatablePlaceholderSnapshot)(BOOL) = ^UIView*(BOOL afterUpdates) {
        // It's easier to use a new UIImageView instance here since the returned image should only
        // be as big as the video itself.
        UIView* snapshotView = [[UIImageView alloc] initWithImage:self.placeholderImage];
        snapshotView.frame = AVMakeRectWithAspectRatioInsideRect(self.placeholderView.intrinsicContentSize, self.bounds);
        
        return snapshotView;
    };
    
    if (!self.playerController.readyForDisplay || CGRectEqualToRect(videoFrame, CGRectZero)) {
        return animatablePlaceholderSnapshot(afterUpdates);
    }
    
    AVAssetImageGenerator* generator = [[AVAssetImageGenerator alloc] initWithAsset:self.playerController.player.currentItem.asset];
    generator.maximumSize = videoFrame.size;
    generator.requestedTimeToleranceBefore = CMTimeMakeWithSeconds(0.1f, 1);
    generator.requestedTimeToleranceAfter = CMTimeMakeWithSeconds(0.1f, 1);
    
    NSError* error = nil;
    CGImageRef rawImage = [generator copyCGImageAtTime:self.playerController.player.currentTime actualTime:NULL error:&error];
    
    if (error) {
        return animatablePlaceholderSnapshot(afterUpdates);
    }
    else {
        UIImage* image = [UIImage imageWithCGImage:rawImage];
        CFRelease(rawImage);
        
        UIView* snapshotView = [[UIImageView alloc] initWithImage:image];
        snapshotView.frame = videoFrame;
        
        return snapshotView;
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect contentFrame = self.bounds;
    if (self.playerController.videoBounds.size.height > 0) {
        contentFrame = [AWKGalleryItemZoomView destinationFrameForSourceFrame:self.playerController.videoBounds inZoomViewBounds:self.bounds];
    } else {
        contentFrame = self.bounds;
    }
    
    self.playerController.view.frame = contentFrame;
    self.placeholderView.frame = contentFrame;
}

- (CGSize)sizeThatFits:(CGSize)size {
    if ([self.item respondsToSelector:@selector(contentSize)] && !CGSizeEqualToSize(CGSizeZero, self.item.contentSize)) {
        return self.item.contentSize;
    }
    if (!CGSizeEqualToSize(self.playerController.videoBounds.size, CGSizeZero)) {
        return self.playerController.videoBounds.size;
    }
    return [UIScreen mainScreen].bounds.size;
}

- (BOOL)prefersFooterViewHidden {
    return !self.repeatingMovie;
}

@end
