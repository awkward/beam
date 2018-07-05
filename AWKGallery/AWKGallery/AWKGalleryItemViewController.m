//
//  AWKGalleryItemViewController.m
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import "AWKGalleryItemViewController.h"

#import "AWKGalleryItem.h"
#import "AWKGalleryItemContentView.h"
#import "AWKGalleryImageContentView.h"
#import "AWKGalleryAnimatedImageContentView.h"
#import "AWKGalleryMovieContentView.h"
#import "AWKGalleryItemZoomView.h"
#import "AWKAnimatedImage.h"
#import <AWKGallery/AWKGallery-Swift.h>
#import "AWKGalleryImageLoader.h"

@interface AWKGalleryItemViewController () <AWKGalleryItemContentViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) AWKGalleryItemZoomView *zoomView;
@property (nonatomic, strong, readwrite) AWKGalleryItemContentView *contentView;
@property (nonatomic, strong) AWKProgressView *progressView;
@property (nonatomic, readwrite, getter=isLoading) BOOL loading;

- (void)zoomViewWasLongPressed:(UILongPressGestureRecognizer*)gestureRecognizer;

@end

@implementation AWKGalleryItemViewController

@dynamic view;

#pragma mark - Accessors

- (void)setContentView:(AWKGalleryItemContentView *)contentView {
    if (![_contentView isEqual:contentView]) {
        _contentView = contentView;
    }
    [self configureContentView];
}

- (BOOL)isDismissableBySwiping {
    return self.zoomView.isZoomedOut;
}

#pragma mark - Initialization

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithItem:nil];
}

- (instancetype)initWithItem:(id<AWKGalleryItem>)item {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _item = item;
        if ([item respondsToSelector:@selector(attributedTitle)]) {
            self.title = [[item attributedTitle] string];
        }
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    return [self initWithItem:nil];
}

#pragma mark - View Lifecycle

- (void)setupView {
    self.view.accessibilityIgnoresInvertColors = true;
    
    self.progressView = ({
        AWKProgressView *progressView = [AWKProgressView new];
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        progressView.tintColor = [UIColor whiteColor];
        progressView;
    });
    [self.view addSubview:self.progressView];
    
    self.zoomView = [[AWKGalleryItemZoomView alloc] initWithFrame:self.view.bounds];
    self.zoomView.backgroundColor = [UIColor clearColor];
    self.zoomView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILongPressGestureRecognizer* recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(zoomViewWasLongPressed:)];
    recognizer.delegate = self;
    [self.zoomView addGestureRecognizer:recognizer];
    [self.view addSubview:self.zoomView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_zoomView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_zoomView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_zoomView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_zoomView)]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
    
    [self prepareContent];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    //iOS 9.3 Doesn't like it if you play videos on a view that is not visible. So pause it
    if ([self.contentView isKindOfClass:[AWKGalleryMovieContentView class]]) {
        [(AWKGalleryMovieContentView *)self.contentView pause];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //iOS 9.3 Doesn't like it if you play videos on a view that is not visible. So play it
    if (self.visible && [self.contentView isKindOfClass:[AWKGalleryMovieContentView class]]) {
        [(AWKGalleryMovieContentView *)self.contentView play];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self configureContentView];
}

#pragma mark - Content

- (void)setVisible:(BOOL)visible {
    _visible = visible;
    
    if ([self.contentView isKindOfClass:[AWKGalleryMovieContentView class]]) {
        if (visible) {
            [(AWKGalleryMovieContentView *)self.contentView play];
        } else {
            [(AWKGalleryMovieContentView *)self.contentView pause];
        }
    }
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    
    if (loading) {
        UIImage *placeholderImage = self.placeholderImage;
        if (placeholderImage) {
            AWKGalleryImageContentView *imageView = [[AWKGalleryImageContentView alloc] initWithItem:self.item];
            imageView.image = placeholderImage;
            self.contentView = imageView;
        } else {
            self.progressView.hidden = false;
        }
        self.zoomView.hidden = (placeholderImage == nil);
    } else {
        self.progressView.hidden = true;
        self.zoomView.hidden = NO;
    }
}

- (void)prepareContent {
    // Download the whole content if we have image content without the image (because it is not cached), or we don't know what we have.
    if (self.item.contentType == AWKGalleryItemContentTypeImage ||
        self.item.contentType == AWKGalleryItemContentTypeAnimatedImage ||
        self.item.contentType == AWKGalleryItemContentTypeUnknown) {
        
        if ([self.item respondsToSelector:@selector(contentData)]) {
            id data = [self.item contentData];
            if (data) {
                [self configureContentViewWithData:data];
                return;
            }
        }
        
        [self fetchContentToDisk];
    }
    else {
        [self configureContentViewWithURL:self.item.contentURL];
    }
}

- (void)fetchContentToDisk {
    self.loading = YES;
    
    __weak typeof(self) weakSelf = self;
    [self.imageLoader downloadImageWithURL:self.item.contentURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            if (weakSelf.onFetchFailure != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.onFetchFailure(weakSelf.item, error);
                });
            }
        } else {
            // Get to know what kind of content we have, by looking at the HTTP Content-Type header.
            if (weakSelf.item.contentType == AWKGalleryItemContentTypeUnknown &&
                [response isKindOfClass:[NSHTTPURLResponse class]]) {
                
                weakSelf.item.contentType = [weakSelf.class contentTypeForResponse:(NSHTTPURLResponse *)response];
            }
            
            // Set the actual content
            if (weakSelf.item.contentType == AWKGalleryItemContentTypeImage ||
                weakSelf.item.contentType == AWKGalleryItemContentTypeAnimatedImage) {
                [weakSelf configureContentViewWithURL:location];
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.loading = NO;
                });
            } else {
                [weakSelf configureContentViewWithURL:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.loading = NO;
                });
            }
        }
    } progressHandler:^(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progressView.progress = (CGFloat)totalBytesWritten/(CGFloat)totalBytesExpectedToWrite;
        });
    }];
}

+ (AWKGalleryItemContentType)contentTypeForResponse:(NSHTTPURLResponse *)response {
    NSString *mimeType = ((NSHTTPURLResponse *)response).allHeaderFields[@"Content-Type"];
    NSString *contentCategory = [mimeType pathComponents].firstObject;
    if ([mimeType isEqualToString:@"image/gif"]) {
        return AWKGalleryItemContentTypeAnimatedImage;
    } else if ([contentCategory isEqualToString:@"image"]) {
        return AWKGalleryItemContentTypeImage;
    } else if ([contentCategory isEqualToString:@"video"]) {
        return AWKGalleryItemContentTypeMovie;
    } else {
        return AWKGalleryItemContentTypeUnknown;
    }
}

/**
 Method to load contents of the file URL. Can be called from the background thread to process data on that thread.
 @param url Either a file URL (image or movie) or a remote URL (only movies), depending on the content type.
 */
- (void)configureContentViewWithURL:(NSURL *)url {
    // Set content view subclass specific properties
    AWKGalleryItemContentType contentType = self.item.contentType;
    switch (contentType) {
        case AWKGalleryItemContentTypeImage:
            [self configureImageContentViewWithURL:url];
            break;
        case AWKGalleryItemContentTypeAnimatedImage:
            [self configureAnimatedImageContentViewWithURL:url];
            break;
        case AWKGalleryItemContentTypeMovie:
            [self configureMovieContentViewWithURL:url];
            break;
        case AWKGalleryItemContentTypeRepeatingMovie:
            [self configureMovieContentViewWithURL:url];
            break;
        default:
            dispatch_async(dispatch_get_main_queue(), ^{
                self.contentView = [[AWKGalleryItemContentView alloc] initWithItem:self.item];
            });
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureContentView];
    });
}

- (void)configureContentViewWithData:(id)data {
    if (data) {
        AWKGalleryItemContentType contentType = self.item.contentType;
        switch (contentType) {
            case AWKGalleryItemContentTypeImage:
                if ([data isKindOfClass:[UIImage class]]) {
                    [self configureImageContentViewWithImage:data];
                }
                break;
            case AWKGalleryItemContentTypeAnimatedImage:
                [self configureAnimatedImageContentViewWithData:data];
                break;
            default:
                NSLog(@"Gallery warning: you should only use use in-memory content data for (animated) images!");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.contentView = [[AWKGalleryItemContentView alloc] initWithItem:self.item];
                });
                break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureContentView];
        });
    }
}

- (NSData *)readContentsOfFileURL:(NSURL *)url {
    NSData *data;
    if (url && url.isFileURL) {
        NSError *readError;
        data = [[NSData alloc] initWithContentsOfFile:url.path options:0 error:&readError];
        if (readError && self.onFetchFailure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.onFetchFailure(self.item, readError);
            });
        }
    }
    return data;
}

- (void)configureMovieContentViewWithURL:(NSURL *)url {
    if (!url) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self.contentView isKindOfClass:[AWKGalleryMovieContentView class]]) {
            self.contentView = [[AWKGalleryMovieContentView alloc] initWithItem:self.item];
        }
        
        ((AWKGalleryMovieContentView *)self.contentView).placeholderImage = self.placeholderImage;
        ((AWKGalleryMovieContentView *)self.contentView).videoURL = url;
        if (self.visible) {
            [(AWKGalleryMovieContentView *)self.contentView play];
        }
    });
}

- (void)configureImageContentViewWithURL:(NSURL *)url {
    if (![url isFileURL]) return;
    UIImage *image = [UIImage downscaledImageWithFileURL:url constrainingSize:self.view.bounds.size contentMode:UIViewContentModeScaleAspectFill];
    if ([self.item respondsToSelector:@selector(setContentData:)]) {
        [self.item setContentData:image];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureImageContentViewWithImage:image];
    });
}

- (void)configureImageContentViewWithImage:(UIImage *)image {
    AWKGalleryImageContentView *imageContentView = [[AWKGalleryImageContentView alloc] initWithItem:self.item];
    imageContentView.image = image;
    self.contentView = imageContentView;
}

- (void)configureAnimatedImageContentViewWithURL:(NSURL *)url {
    if (![url isFileURL]) return;
    NSData *imageData = [self readContentsOfFileURL:url];
    if ([self.item respondsToSelector:@selector(setContentData:)]) {
        [self.item setContentData:imageData];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureAnimatedImageContentViewWithData:imageData];
    });
}

- (void)configureAnimatedImageContentViewWithData:(NSData *)imageData {
    if (![self.contentView isKindOfClass:[AWKGalleryAnimatedImageContentView class]]) {
        self.contentView = [[AWKGalleryAnimatedImageContentView alloc] initWithItem:self.item];
    }
    
    if (imageData) {
        [(AWKGalleryAnimatedImageContentView *)self.contentView setAnimatedImage:[AWKAnimatedImage animatedImageWithGIFData:imageData]];
    }
}

- (void)configureContentView {
    self.zoomView.contentView = self.contentView;
    self.zoomView.scrollEnabled = self.contentView.shouldZoomAndPan;
    
    CGSize size = [self.contentView sizeThatFits:CGSizeZero];
    self.contentView.bounds = CGRectMake(0, 0, size.width, size.height);
    [self.zoomView resetContentViewPosition];
    
    if (!self.contentView.shouldZoomAndPan) {
        self.zoomView.minimumZoomScale = 1;
        self.zoomView.maximumZoomScale = 1;
        self.zoomView.zoomScale = 1;
    }
}

- (void)zoomViewWasLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (!self.presentedViewController) {
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            if ([self.item contentType] == AWKGalleryItemContentTypeImage || [self.item contentType] == AWKGalleryItemContentTypeAnimatedImage) {
                if (!self.loading && [self.contentView isKindOfClass:[AWKGalleryImageContentView class]]) {
                    UIImage* image = ((AWKGalleryImageContentView*)self.contentView).image;
                    if (image) {
                        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
                        controller.popoverPresentationController.sourceRect = self.contentView.frame;
                        controller.popoverPresentationController.sourceView = self.zoomView;
                        [self presentViewController:controller animated:YES completion:nil];
                    }
                }
            }
        }
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
