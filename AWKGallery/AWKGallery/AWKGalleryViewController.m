//
//  AWKGalleryViewController.m
//  Gallery
//
//  Created by Robin Speijer on 28-04-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AWKGalleryViewController.h"

#import "AWKGalleryItemViewController.h"
#import "AWKGalleryItemContentView.h"
#import "AWKGalleryAnimator.h"
#import "AWKGalleryItemFooterDescriptionView.h"
#import "AWKGalleryItemExpandedDescriptionView.h"
#import "AWKGalleryLayoutGuide.h"
#import "AWKGalleryImageLoader.h"

#import <AWKGallery/AWKGallery-Swift.h>

static const NSTimeInterval AWKGalleryViewControllerDefaultAnimationDuration = 0.3;

@interface AWKGalleryViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate, AWKGalleryItemFooterDescriptionViewDelegate, AWKGalleryItemExpandedDescriptionViewDelegate, UINavigationBarDelegate>

// View Controller
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) id animator;
@property (readwrite, nonatomic) UINavigationItem *navigationItem;

// Views
@property (strong, nonatomic) UINavigationBar *navigationBar;
@property (strong, nonatomic) AWKGradientView *topGradientView;
@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) AWKGalleryFooterGradientView *footerGradientView;
@property (strong, nonatomic) AWKGalleryItemFooterDescriptionView *footerDescriptionView;
@property (strong, nonatomic) AWKGalleryItemExpandedDescriptionView *expandedDescriptionView;
@property (assign, nonatomic) BOOL secondaryViewsVisible;
@property (assign, nonatomic) BOOL secondaryViewsVisibleInPortrait;
@property (strong, nonatomic) NSLayoutConstraint *footerBottomConstraint;
@property (strong, nonatomic) NSLayoutConstraint *footerBottomToolbarConstraint;


// Touch handling
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

// Audio
@property (strong, nonatomic) NSString* originalAudioSessionCategory;
@property (assign, nonatomic) AVAudioSessionCategoryOptions originalAudioSessionCategoryOptions;

// Data
@property (nonatomic, readonly) NSString *currentItemTitle;

// Networking
@property (nonatomic, strong) AWKGalleryImageLoader *imageLoader;

@end

@implementation AWKGalleryViewController {
    BOOL constraintsAdded;
    CGPoint panAnchor;
}

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupGalleryViewController];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupGalleryViewController];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setupGalleryViewController];
    }
    return self;
}

- (void)setupGalleryViewController {
    self.shouldAutomaticallyDisplaySecondaryViews = YES;
    self.itemSpacing = 10.0f;
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.modalPresentationCapturesStatusBarAppearance = YES;
    self.transitioningDelegate = self;
    self.displaysNavigationItemCount = NO;
    self.navigationItem = [[UINavigationItem alloc] initWithTitle:@""];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissGallery:)];
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    self.imageLoader = [[AWKGalleryImageLoader alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationBar.items  = @[self.navigationItem];
    
    if (self.pageViewController.viewControllers.count == 0 && [self.dataSource numberOfItemsInGallery: self] > 0) {
        self.currentItem = [self.dataSource gallery:self itemAtIndex:0];
    }
    
    AVAudioSession* session = [AVAudioSession sharedInstance];
    self.originalAudioSessionCategory = session.category;
    self.originalAudioSessionCategoryOptions = session.categoryOptions;
    
    [self configureAudioSessionWithItem:self.currentItem];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(self.shouldAutomaticallyDisplaySecondaryViews) {
        [self setSecondaryViewsVisible:YES animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self configureAudioSessionWithItem:nil];
}

- (void)dealloc {
    self.pageViewController = nil;
}

#pragma mark - Layout

- (UIPageViewController *)pageViewController {
    if (self.view) {
        return _pageViewController;
    } else {
        return nil;
    }
}

- (void)reloadData {
    //This calls setViewControllers: on UIPageViewController to refresh the odrer.
    self.currentItem = self.currentItem;
}

- (void)setupView {
    self.view.backgroundColor = [UIColor galleryBackgroundColor];
    self.view.accessibilityIgnoresInvertColors = true;
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:@{UIPageViewControllerOptionInterPageSpacingKey: @(self.itemSpacing)}];
    self.pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    [self.view addSubview:self.pageViewController.view];
    [self addChildViewController:self.pageViewController];
    
    self.footerGradientView = ({
        AWKGalleryFooterGradientView *view = [[AWKGalleryFooterGradientView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.alpha = 0;
        view;
    });
    [self.view addSubview:self.footerGradientView];
    
    self.footerDescriptionView = ({
        AWKGalleryItemFooterDescriptionView *footer = [[AWKGalleryItemFooterDescriptionView alloc] initWithFrame:CGRectZero];
        footer.translatesAutoresizingMaskIntoConstraints = NO;
        footer.alpha = 0.0f;
        footer;
    });
    self.footerDescriptionView.delegate = self;
    [self.view addSubview:self.footerDescriptionView];
    
    self.expandedDescriptionView = ({
        AWKGalleryItemExpandedDescriptionView *expanded = [[AWKGalleryItemExpandedDescriptionView alloc] initWithFrame:CGRectZero];
        expanded.translatesAutoresizingMaskIntoConstraints = NO;
        expanded.alpha = 0;
        expanded;
    });
    self.expandedDescriptionView.delegate = self;
    [self.view addSubview:self.expandedDescriptionView];
    
    self.topGradientView = ({
        AWKGradientView *gradientView = [[AWKGradientView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 64)];
        gradientView.translatesAutoresizingMaskIntoConstraints = NO;
        gradientView.direction = UILayoutConstraintAxisVertical;
        gradientView.fromColor = [[UIColor galleryBackgroundColor] colorWithAlphaComponent:0.9f];
        gradientView.toColor = [UIColor clearColor];
        gradientView.alpha = 0;
        gradientView;
    });
    [self.view addSubview:self.topGradientView];
    
    self.navigationBar = ({
        UINavigationBar *bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
        bar.translatesAutoresizingMaskIntoConstraints = NO;
        bar.barStyle = UIBarStyleBlack;
        bar.barTintColor = [UIColor clearColor];
        bar.translucent = YES;
        bar.delegate = self;
        bar.tintColor = [UIColor whiteColor];
        [bar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
        [bar setShadowImage:[[UIImage alloc] init]];
        bar.alpha = 0;
        bar;
    });
    [self.view addSubview:self.navigationBar];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissalPanGesture:)];
    self.panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    self.tapGestureRecognizer.cancelsTouchesInView = YES;
    self.tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat bottomViewHeight = self.bottomView ? CGRectGetHeight(self.bottomView.bounds) : 0;
    self.footerGradientView.relativeMidLocation = 1 - (0.55 * (bottomViewHeight / CGRectGetHeight(self.footerGradientView.bounds)));
    
    self.expandedDescriptionView.layoutMargins = UIEdgeInsetsMake(64, 12, bottomViewHeight, 12);
}

- (void)updateViewConstraints {
    if (!constraintsAdded) {
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_navigationBar]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_navigationBar)]];
        id topLayoutGuide = self.topLayoutGuide;
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][_navigationBar]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(topLayoutGuide, _navigationBar)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_topGradientView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_topGradientView)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_topGradientView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_topGradientView)]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_topGradientView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_navigationBar attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
        
        [self.footerDescriptionView addConstraint:[NSLayoutConstraint constraintWithItem:self.footerDescriptionView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:115]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_expandedDescriptionView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_expandedDescriptionView)]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.expandedDescriptionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        [self.expandedDescriptionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = true;
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_footerDescriptionView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_footerDescriptionView)]];
        self.footerBottomConstraint = [self.footerDescriptionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
        self.footerBottomConstraint.priority = UILayoutPriorityDefaultLow;
        [self.view addConstraint:self.footerBottomConstraint];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_footerGradientView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_footerGradientView)]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.footerGradientView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.footerDescriptionView attribute:NSLayoutAttributeTop multiplier:1 constant:-30]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.footerGradientView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
        
        constraintsAdded = YES;
    }
    
    [super updateViewConstraints];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (void)setBottomView:(UIView *)bottomView {
    if (_bottomView != bottomView) {
        
        if (_bottomView) {
            [_bottomView removeFromSuperview];
            self.footerBottomToolbarConstraint = nil;
        }
        
        _bottomView = bottomView;
        
        if (bottomView) {
            bottomView.translatesAutoresizingMaskIntoConstraints = NO;
            bottomView.alpha = self.footerDescriptionView.alpha;
            [self.view addSubview:bottomView];
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(bottomView)]];
            [self.view addConstraint:[self.view.safeAreaLayoutGuide.bottomAnchor constraintEqualToAnchor:bottomView.bottomAnchor]];
            
            self.footerBottomToolbarConstraint = [NSLayoutConstraint constraintWithItem:self.footerDescriptionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
            self.footerBottomToolbarConstraint.priority = UILayoutPriorityRequired;
            [self.view addConstraint:self.footerBottomToolbarConstraint];
            
        }
        
        [self.view setNeedsUpdateConstraints];
    }
}

- (id<UILayoutSupport>)galleryBottomLayoutGuide {
    return [[AWKGalleryLayoutGuide alloc] initWithGalleryViewController:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotate {
    return true;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    //If the width is higher than the height we are in landscape, if the space is less than 400 points, hide the secondary views to make the image visible
    if(size.width > size.height && size.height < 400) {
        self.secondaryViewsVisibleInPortrait = self.secondaryViewsVisible;
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self setSecondaryViewsVisible:false];
        } completion:nil];
    } else if(size.height > size.width && size.height > 400) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self setSecondaryViewsVisible:self.secondaryViewsVisibleInPortrait];
        } completion:nil];
    }
}

#pragma mark - AWKGalleryViewController

- (void)updateItemMetadata {
    self.footerDescriptionView.item = self.currentItem;
    self.expandedDescriptionView.item = self.currentItem;
    
    // The footerview changes it's own hidden property depending on if there's content. Now hide it anyway if the content view prefers that.
    if ([self.pageViewController.viewControllers.firstObject isKindOfClass:[AWKGalleryItemViewController class]] &&
        [(AWKGalleryItemViewController *)self.pageViewController.viewControllers.firstObject contentView].prefersFooterViewHidden) {
        self.footerDescriptionView.hidden = YES;
    }
    
    self.navigationItem.title = self.currentItemTitle;
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    [self.view setNeedsUpdateConstraints];
}

- (id<AWKGalleryItem>)currentItem {
    UIViewController *visibleViewController = self.pageViewController.viewControllers.firstObject;
    if ([visibleViewController conformsToProtocol:@protocol(AWKGalleryItemContent)]) {
        return [(UIViewController<AWKGalleryItemContent> *)visibleViewController item];
    }
    return nil;
}

- (void)setCurrentItem:(id<AWKGalleryItem>)currentItem {
    UIViewController *viewController = [self itemViewControllerWithItem:currentItem];
    [self.pageViewController setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished){
        
        if ([viewController isKindOfClass:[AWKGalleryItemViewController class]]) {
            ((AWKGalleryItemViewController *)viewController).visible = YES;
        }
        
    }];

    [self updateItemMetadata];
}

- (NSString *)currentItemTitle {
    NSInteger count = [self.dataSource numberOfItemsInGallery:self];
    if (count > 1 && self.displaysNavigationItemCount) {
        NSInteger itemNumber = [self.dataSource gallery:self indexOfItem:self.currentItem] + 1;
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"index-of-count", @"Localizable", [NSBundle bundleForClass:self.class], @"'<index> of <number of gallery items>' at the top of the gallery"), itemNumber, count];
    }
    return @"";
}

- (UIViewController<AWKGalleryItemContent> *)currentContentViewController {
    UIViewController *currentViewController = self.pageViewController.viewControllers.firstObject;
    if ([currentViewController conformsToProtocol:@protocol(AWKGalleryItemContent)]) {
        return (UIViewController<AWKGalleryItemContent> *)currentViewController;
    }
    return nil;
}

- (UIView *)currentContentView {
    return [self currentContentViewController].contentView;
}

#pragma mark - Actions

- (IBAction)dismissGallery:(id)sender {
    [self dismissViewControllerAnimated:YES];
}

- (void)dismissViewControllerAnimated:(BOOL)animated {
    UIViewController<AWKGalleryItemContent> *previousVC = self.pageViewController.viewControllers.firstObject;
    if ([previousVC isKindOfClass:[AWKGalleryItemViewController class]]) {
        previousVC.visible = NO;
    } else if ([self.delegate respondsToSelector:@selector(gallery:shouldBeDismissedWithCustomContentViewController:)]) {
        [self.delegate gallery:self shouldBeDismissedWithCustomContentViewController:previousVC];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(gallery:shouldBeDismissedAnimated:)]) {
        [self.delegate gallery:self shouldBeDismissedAnimated:animated];
    } else {
        [self dismissViewControllerAnimated:animated completion:nil];
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self setSecondaryViewsVisible:!self.secondaryViewsVisible animated:YES];
}

#pragma mark - Transition

- (void)configureAnimatorForDismissal:(BOOL)dismissal {
    if ([self.delegate respondsToSelector:@selector(gallery:presentationAnimationSourceViewForItem:)]) {
        UIView *sourceView = [self.delegate gallery:self presentationAnimationSourceViewForItem:self.currentItem];
        self.animator = [[AWKGalleryAnimator alloc] init];
        ((AWKGalleryAnimator *)self.animator).sourceView = sourceView;
        ((AWKGalleryAnimator *)self.animator).dismissal = dismissal;
        __weak typeof(self) weakSelf = self;
        ((AWKGalleryAnimator *)self.animator).onAnimationEndHandler = ^(BOOL completed) {
            weakSelf.animator = nil;
        };
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    if (presented == self) {
        [self configureAnimatorForDismissal:NO];
        return self.animator;
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if (dismissed == self) {
        [self configureAnimatorForDismissal:YES];
        return self.animator;
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
    return nil;
}

- (void)handleDismissalPanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        panAnchor = [gestureRecognizer locationInView:self.view];
        [self setSecondaryViewsVisible:NO animated:YES];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint newPoint = [gestureRecognizer locationInView:self.view];
        CGPoint offset = CGPointMake(newPoint.x-panAnchor.x, newPoint.y-panAnchor.y);
        self.pageViewController.view.center = CGPointMake(self.pageViewController.view.center.x, CGRectGetMidY(self.view.bounds)+offset.y);

        CGFloat percent = fabs((0.5f * offset.y)/CGRectGetHeight(self.view.bounds));
        self.pageViewController.view.alpha = MAX(1.0-percent, 0);
        self.view.backgroundColor = [UIColor.galleryBackgroundColor colorWithAlphaComponent:1.0f-percent];
        
        CGFloat scale = (1.0f-percent);
        self.pageViewController.view.transform = CGAffineTransformMakeScale(scale, scale);
        
    } else if (gestureRecognizer.state == UIGestureRecognizerStateCancelled || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        self.pageViewController.view.center = CGPointMake(self.pageViewController.view.center.x, CGRectGetMidY(self.view.bounds));
        [self.backgroundView removeFromSuperview];
        self.backgroundView = nil;
        self.secondaryViewsVisible = YES;
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint newPoint = [gestureRecognizer locationInView:self.view];
        CGPoint offset = CGPointMake(newPoint.x-panAnchor.x, newPoint.y-panAnchor.y);
        CGFloat percent = fabs(offset.y/CGRectGetHeight(self.view.bounds));
        if (percent > 0.1f) {
            [self dismissViewControllerAnimated:YES];
        } else {
            [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
                self.pageViewController.view.center = CGPointMake(self.pageViewController.view.center.x, CGRectGetMidY(self.view.bounds));
                self.pageViewController.view.transform = CGAffineTransformIdentity;
                self.view.backgroundColor = [UIColor galleryBackgroundColor];
            } completion:^(BOOL finished) {
                [self.backgroundView removeFromSuperview];
                self.backgroundView = nil;
                
                [self setSecondaryViewsVisible:YES animated:YES];
            }];
        }
    }
}

#pragma mark - UINavigationBarDelegate

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if ([viewController conformsToProtocol:@protocol(AWKGalleryItemContent)]) {
        id<AWKGalleryItem> item = [(UIViewController<AWKGalleryItemContent> *)viewController item];
        NSInteger index = [self.dataSource gallery:self indexOfItem:item];
        if (index > 0) {
            id<AWKGalleryItem> previousItem = [self.dataSource gallery:self itemAtIndex:index-1];
            return [self itemViewControllerWithItem:previousItem];
        }
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if ([viewController conformsToProtocol:@protocol(AWKGalleryItemContent)]) {
        id<AWKGalleryItem> item = [(UIViewController<AWKGalleryItemContent> *)viewController item];
        NSInteger index = [self.dataSource gallery:self indexOfItem:item];
        if (index < [self.dataSource numberOfItemsInGallery:self]-1) {
            id<AWKGalleryItem> nextItem = [self.dataSource gallery:self itemAtIndex:index+1];
            return [self itemViewControllerWithItem:nextItem];
        }
    }
    if (!viewController) {
        id<AWKGalleryItem> item = [self.dataSource gallery:self itemAtIndex:0];
        return [self itemViewControllerWithItem:item];
    }
    return nil;
}

- (UIViewController<AWKGalleryItemContent> *)itemViewControllerWithItem:(id<AWKGalleryItem>)item {
    UIViewController<AWKGalleryItemContent> *viewController;
    if ([self.dataSource respondsToSelector:@selector(gallery:contentViewControllerForItem:)]) {
        viewController = [self.dataSource gallery:self contentViewControllerForItem:item];
        viewController.item = item;
    }
    
    if (!viewController) {
        viewController = [self newItemViewControllerWithItem:item];
    }
    
    return viewController;
}

- (AWKGalleryItemViewController *)newItemViewControllerWithItem:(id<AWKGalleryItem>)item {
    AWKGalleryItemViewController *viewController = [[AWKGalleryItemViewController alloc] initWithItem:item];
    viewController.imageLoader = self.imageLoader;
    __weak typeof(self) weakSelf = self;
    [viewController setOnFetchFailure:^(id<AWKGalleryItem> item, NSError *error) {
        if (weakSelf.delegate && [weakSelf respondsToSelector:@selector(gallery:failedLoadingItem:withError:)]) {
            [weakSelf.delegate gallery:weakSelf failedLoadingItem:item withError:error];
        }
    }];
    
    if ([item respondsToSelector:@selector(placeholderImage)]) {
        viewController.placeholderImage = [item placeholderImage];
    }
    
    if (!viewController.placeholderImage && [self.delegate respondsToSelector:@selector(gallery:presentationAnimationSourceViewForItem:)]) {
        UIView *sourceView = [self.delegate gallery:self presentationAnimationSourceViewForItem:item];
        if ([sourceView isKindOfClass:[UIImageView class]]) {
            viewController.placeholderImage = [(UIImageView *)sourceView image];
        } else if (sourceView) {
            UIGraphicsBeginImageContextWithOptions(sourceView.bounds.size, NO, [UIScreen mainScreen].scale);
            [sourceView drawViewHierarchyInRect:sourceView.bounds afterScreenUpdates:NO];
            viewController.placeholderImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    
    return viewController;
}

#pragma mark - UIPageViewControllerDelegate 

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    
    [self willChangeValueForKey:@"currentItem"];
    
    UIViewController<AWKGalleryItemContent> *newPage = pendingViewControllers.firstObject;
    newPage.visible = YES;
    
    if ([self.delegate respondsToSelector:@selector(gallery:willScrollToItem:)]) {
        [self.delegate gallery:self willScrollToItem:newPage.item];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    [self didChangeValueForKey:@"currentItem"];
    
    UIViewController<AWKGalleryItemContent> *oldViewController = previousViewControllers.firstObject;
    oldViewController.visible = NO;
    
    
    [self updateItemMetadata];
    [self configureAudioSessionWithItem:self.currentItem];
    
    if ([self.delegate respondsToSelector:@selector(gallery:didScrollFromItem:)]) {
        [self.delegate gallery:self didScrollFromItem:oldViewController.item];
    }
}

#pragma mark - AWKGalleryFooterViewDelegate

- (BOOL)footerView:(AWKGalleryItemFooterDescriptionView *)footerView shouldInteractWithURL:(NSURL *)URL {
    if ([self.delegate respondsToSelector:@selector(gallery:item:shouldInteractWithURL:)]) {
        return [self.delegate gallery:self item:self.currentItem shouldInteractWithURL:URL];
    } else {
        return YES;
    }
}

- (void)tappedExpansionButtonForFooterView:(AWKGalleryItemFooterDescriptionView *)footerView {
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.footerDescriptionView.alpha = 0;
        self.expandedDescriptionView.alpha = 1;
    } completion:nil];
}

- (void)tappedExpandedItemView:(AWKGalleryItemExpandedDescriptionView *)itemView {
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.footerDescriptionView.alpha = 1;
        self.expandedDescriptionView.alpha = 0;
    } completion:nil];
}

- (NSString *)expansionButtonTitleInFooterView:(AWKGalleryItemFooterDescriptionView *)footerView {
    return NSLocalizedStringFromTableInBundle(@"read-more", @"Localizable", [NSBundle bundleForClass:self.class], @"Read more button below the image caption");
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return self.expandedDescriptionView.alpha < 0.1f && [self.currentContentViewController isKindOfClass:[AWKGalleryItemViewController class]] && ((AWKGalleryItemViewController *)self.currentContentViewController).dismissableBySwiping;
    }
    
    if ([self.tapGestureRecognizer isEqual:gestureRecognizer]) {
        return [[self currentContentView] isKindOfClass:[AWKGalleryItemContentView class]] && [[self.view hitTest:[gestureRecognizer locationInView:self.view] withEvent:nil] isDescendantOfView:self.currentContentViewController.view];
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isEqual:self.tapGestureRecognizer]) {
        return ![otherGestureRecognizer.view isDescendantOfView:[self currentContentView]];
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [otherGestureRecognizer.view isDescendantOfView:[self currentContentView]];
}

#pragma mark - Secondary views

- (void)setSecondaryViewsVisible:(BOOL)secondaryViewsVisible {
    
    if (_secondaryViewsVisible != secondaryViewsVisible) {
        _secondaryViewsVisible = secondaryViewsVisible;
        
        CGFloat alpha = secondaryViewsVisible ? 1.0f : 0.0f;
        self.navigationBar.alpha = alpha;
        self.topGradientView.alpha = alpha;
        self.footerDescriptionView.alpha = alpha;
        self.footerGradientView.alpha = alpha;
        self.bottomView.alpha = alpha;
    }
    
}

- (void)setSecondaryViewsVisible:(BOOL)secondaryViewsVisible animated:(BOOL)animated {
    if (!animated) {
        self.secondaryViewsVisible = secondaryViewsVisible;
    } else {
        [UIView animateWithDuration:AWKGalleryViewControllerDefaultAnimationDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:0 animations:^{
            self.secondaryViewsVisible = secondaryViewsVisible;
        } completion:nil];
    }
}

#pragma mark - Audio Session

- (void)configureAudioSessionWithItem:(id<AWKGalleryItem>)item {
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    if (item && ([item contentType] == AWKGalleryItemContentTypeRepeatingMovie || [item contentType] == AWKGalleryItemContentTypeAnimatedImage)) {
        [session setCategory:AVAudioSessionCategoryAmbient withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    } else if (item && [item contentType] == AWKGalleryItemContentTypeMovie) {
        [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    } else if (item == nil) {
        [session setActive:NO error:nil];
        [session setCategory:self.originalAudioSessionCategory withOptions:self.originalAudioSessionCategoryOptions error:nil];
    }
}

@end
