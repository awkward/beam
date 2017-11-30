//
//  AWKViewController.m
//  AWKGallery
//
//  Created by Laurin Brandner on 05/21/2015.
//  Copyright (c) 2014 Laurin Brandner. All rights reserved.
//

#import "AWKViewController.h"

#import <AWKGallery/AWKGallery.h>
#import "GalleryItem.h"

@interface AWKViewController () <AWKGalleryDataSource, AWKGalleryDelegate>

@property (nonatomic, strong) NSArray *galleryItems;

@property (weak, nonatomic) IBOutlet UIButton *openButton;
@property (weak, nonatomic) IBOutlet UIButton *openButton2;

@end

@implementation AWKViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.openButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.openButton2.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

#pragma mark - Actions

- (IBAction)openGallery:(UIButton *)sender {
    AWKGalleryViewController *viewController = [[AWKGalleryViewController alloc] init];
    viewController.itemSpacing = 5;
    viewController.dataSource = self;
    viewController.delegate = self;
    viewController.currentItem = self.galleryItems[sender.tag];
    
    [self presentViewController:viewController animated:YES completion:^(){
        // Hide the open button, because it's content is already visible in the gallery. We don't want to act like the gallery is a photocopy of the source view.
        sender.hidden = YES;
    }];
}

- (NSArray *)galleryItems {
    if (!_galleryItems) {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        [items addObjectsFromArray:@[[GalleryItem itemWithImageURL:[NSURL URLWithString:@"http://www.flevosprong.nl/content/data/nieuws/kuikens.jpg"]],
                                     [GalleryItem itemWithAnimatedImageURL:[NSURL URLWithString:@"http://i.giphy.com/Alyf78EYOVofC.gif"]],
                                     [GalleryItem itemWithMovieURL:[NSURL URLWithString:@"http://techslides.com/demos/sample-videos/small.mp4"]]]];
        [items[0] setPlaceholderImage:[UIImage imageNamed:@"example1"]];
        [items[1] setPlaceholderImage:[UIImage imageNamed:@"example2"]];
        _galleryItems = items;
    }
    return _galleryItems;
}

#pragma mark - AWKGalleryDataSource

- (NSInteger)numberOfItemsInGallery:(AWKGalleryViewController *)galleryViewController {
    return self.galleryItems.count;
}

- (id<AWKGalleryItem>)gallery:(AWKGalleryViewController *)galleryViewController itemAtIndex:(NSUInteger)index {
    return self.galleryItems[index];
}

- (NSInteger)gallery:(AWKGalleryViewController *)galleryViewController indexOfItem:(id<AWKGalleryItem>)item {
    return [self.galleryItems indexOfObject:item];
}

#pragma mark - AWKGalleryDelegate

- (void)gallery:(AWKGalleryViewController *)galleryViewController failedLoadingItem:(id<AWKGalleryItem>)item withError:(NSError *)error {
    NSLog(@"Failed to load gallery item %@: %@", item, error);
}

- (UIView *)gallery:(AWKGalleryViewController *)galleryViewController presentationAnimationSourceViewForItem:(id<AWKGalleryItem>)item {
    return [self buttonForItem:item];
}

- (UIButton *)buttonForItem:(id<AWKGalleryItem>)item {
    NSInteger index = [self.galleryItems indexOfObject:item];
    if (index == 0) {
        return self.openButton;
    } else if (index == 1) {
        return self.openButton2;
    } else {
        return nil;
    }
}

- (void)gallery:(AWKGalleryViewController *)galleryViewController willScrollToItem:(id<AWKGalleryItem>)item {
    [self buttonForItem:item].hidden = YES;
}

- (void)gallery:(AWKGalleryViewController *)galleryViewController didScrollFromItem:(id<AWKGalleryItem>)item {
    [self buttonForItem:item].hidden = NO;
}

- (void)gallery:(AWKGalleryViewController *)galleryViewController shouldBeDismissedAnimated:(BOOL)animated {
    [galleryViewController dismissViewControllerAnimated:animated completion:^(){
        // Because the content is back to it's original location and the gallery's animation view is going to disappear, we can show our original view again.
        GalleryItem *item = galleryViewController.currentItem;
        [self buttonForItem:item].hidden = NO;
    }];
}

@end
