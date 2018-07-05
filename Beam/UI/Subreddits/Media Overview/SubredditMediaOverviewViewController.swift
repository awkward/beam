//
//  SubredditMediaOverviewViewController.swift
//  beam
//
//  Created by Robin Speijer on 12-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import AWKGallery
import Trekker
import CoreData

class SubredditMediaOverviewViewController: BeamViewController, SubredditTabItemViewController, PostMetadataViewDelegate, HidingButtonBarDelegate {
    
    var imagesInRow = 3 {
        didSet {
            if self.imagesInRow != oldValue {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }
    
    let refreshControl = UIRefreshControl()
    
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var sortingBarItem: UIBarButtonItem!
    @IBOutlet var sortingBar: ScrollableButtonBar!
    @IBOutlet var topButtonBarConstraint: NSLayoutConstraint!
    var lastButtonBarScrollViewOffset: CGPoint?
    var lastScrollViewOffset: CGPoint?
    var lastScrollViewOffsetCapture: TimeInterval?
    @IBOutlet var collectionView: UICollectionView!
    
    weak var galleryViewController: AWKGalleryViewController?
    
    var titleView = SubredditTitleView.titleViewWithSubreddit(nil)
    
    weak var subreddit: Subreddit? {
        didSet {
            self.updateNavigationItem()
            if let subreddit = subreddit {
                self.mediaCollectionController = SubredditMediaCollectionController(subreddit: subreddit)
            } else {
                self.mediaCollectionController = nil
            }
            
        }
    }
    
    fileprivate var loadingState: BeamViewControllerLoadingState = .empty {
        didSet {
            switch self.loadingState {
            case .loading:
                let emptyBackgroundView = BeamEmptyView.emptyView(BeamEmptyViewType.Loading, frame: self.collectionView!.bounds)
                emptyBackgroundView.layoutMargins = self.collectionView.contentInset
                self.collectionView!.backgroundView = emptyBackgroundView
            case .empty:
                let emptyBackgroundView = BeamEmptyView.emptyView(.SubredditMediaViewEmpty, frame: self.collectionView!.bounds)
                emptyBackgroundView.layoutMargins = self.collectionView.contentInset
                if self.mediaCollectionController?.error != nil {
                    emptyBackgroundView.buttonHandler = {(button) -> Void in
                        self.initiallyFetchContent()
                    }
                }
                self.collectionView!.backgroundView = emptyBackgroundView
            case .noInternetConnection:
                let emptyBackgroundView = BeamEmptyView.emptyView(.Error, frame: self.collectionView!.bounds)
                emptyBackgroundView.layoutMargins = self.collectionView.contentInset
                    emptyBackgroundView.buttonHandler = {(button) -> Void in
                        self.initiallyFetchContent()
                }
                self.collectionView!.backgroundView = emptyBackgroundView
            default:
                self.collectionView!.backgroundView = nil
            }
            self.displayModeDidChange()
        }
    }
    
    fileprivate var hasEnteredLoadMoreState = false {
        didSet {
            if self.hasEnteredLoadMoreState == true && oldValue != self.hasEnteredLoadMoreState {
                self.mediaCollectionController?.fetchMoreContent()
            }
        }
    }
    
    //Returns if the collectionView frame is completly filled with images
    fileprivate var collectionViewIsFilled: Bool {
        guard let collectionView = self.collectionView else {
            return false
        }
        
        let itemCount = self.mediaCollectionController?.collection?.count ?? 0
        let rowCount = ceil(CGFloat(itemCount) / CGFloat(self.imagesInRow))
        let contentHeight = rowCount * (self.itemSize.height + self.flowLayout.minimumLineSpacing)
        if collectionView.bounds.height != 0 && collectionView.bounds.height > contentHeight {
            return false
        }
        return true
    }

    fileprivate var mediaCollectionController: SubredditMediaCollectionController? {
        didSet {
            self.collectionView?.reloadData()
            self.mediaCollectionController?.delegate = self
        }
    }
    
    fileprivate var flowLayout: UICollectionViewFlowLayout {
        return self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateNavigationItem()

        self.refreshControl.addTarget(self, action: #selector(SubredditMediaOverviewViewController.refresh(_:)), for: .valueChanged)
        self.collectionView.refreshControl = self.refreshControl
        
        self.flowLayout.minimumInteritemSpacing = 1
        self.flowLayout.minimumLineSpacing = 1
        
        self.changeSorting(self.subreddit?.mediaSortType ?? .hot, timeFrame: self.subreddit?.mediaTimeFrame ?? .thisMonth)
        
        self.sortingBar.items = [AWKLocalizedString("hot"), AWKLocalizedString("new"), AWKLocalizedString("rising"), AWKLocalizedString("controversial"), AWKLocalizedString("top")]
        self.sortingBar.selectedItemIndex = self.sortingBarIndexForSortType(self.subreddit?.mediaSortType ?? .hot)
        self.sortingBar.addTarget(self, action: #selector(SubredditMediaOverviewViewController.sortingBarItemTapped(_:)), for: UIControlEvents.valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditMediaOverviewViewController.settingDidChange(_:)), name: .SubredditNSFWOverlaySettingDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditMediaOverviewViewController.settingDidChange(_:)), name: .SubredditSpoilerOverlaySettingDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditMediaOverviewViewController.contextDidSaveNotification(_:)), name: .NSManagedObjectContextDidSave, object: AppDelegate.shared.managedObjectContext)
        
        let insets = UIEdgeInsets(top: self.toolbar.frame.height, left: 0, bottom: 0, right: 0)
        self.collectionView?.contentInset = insets
        self.collectionView?.scrollIndicatorInsets = insets
        
        self.registerForPreviewing(with: self, sourceView: self.collectionView)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.mediaCollectionController?.isCollectionExpired == true || self.mediaCollectionController?.collection?.count == 0 {
            self.initiallyFetchContent()
        } else if self.collectionViewIsFilled == false && self.mediaCollectionController?.status != .fetching {
            self.startLoadingMoreContentIfPossible()
        }
        
        if self.presentedViewController == nil {
            Trekker.default.track(event: TrekkerEvent(event: "Use media view"))
        }
        
    }
    
    fileprivate func initiallyFetchContent() {
        if self.mediaCollectionController?.count ?? 0 == 0 {
            self.loadingState = .loading
        }
        self.mediaCollectionController?.fetchInitialContent()
        self.collectionView.reloadData()
    }
    
    @objc fileprivate func settingDidChange(_ notification: Notification) {
        let indexPaths = self.collectionView.indexPathsForVisibleItems
        if indexPaths.count > 0 {
             self.collectionView.reloadItems(at: indexPaths)
        }
    }
    
    @objc fileprivate func contextDidSaveNotification(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            
            // Check whether the subreddit in the collection query changed outside of the known collection controller
            if let updatedObjects = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, let postsSubreddit = self.subreddit, self.mediaCollectionController?.status == CollectionControllerStatus.inMemory {
                if updatedObjects.contains(postsSubreddit) {
                    self.mediaCollectionController?.reloadMedia()
                }
            }
        }
    }
    
    // MARK: - Data
    
    func cancelRequests() {
        self.mediaCollectionController?.cancelFetching()
    }
    
    // MARK: - Layout
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.view.bounds.width > 1024 {
            self.imagesInRow = 12
        } else if self.view.bounds.width > 768 {
            self.imagesInRow = 9
        } else if self.view.bounds.width > 438 {
            self.imagesInRow = 6
        } else if self.view.bounds.width > 414 {
            self.imagesInRow = 5
        } else {
            self.imagesInRow = 3
        }
    }
    
    fileprivate var isFirstLayout = true
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.isFirstLayout && self.topLayoutGuide.length > 0 {
            self.isFirstLayout = false
            self.view.setNeedsUpdateConstraints()
        }
        
        self.sortingBarItem.width = self.toolbar.bounds.width
    }
    
    func updateButtonBarVerticalOffset(_ offset: CGFloat) {
        self.topButtonBarConstraint.constant = offset + 0
    }
    
    var buttonBarVerticalOffset: CGFloat {
        return 0
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        self.topButtonBarConstraint.constant = 0
    }
    
    var itemSize: CGSize {
        let side = view.bounds.width / CGFloat(imagesInRow) - flowLayout.minimumInteritemSpacing
        return CGSize(width: side, height: side)
    }
    
    var footerLoaderSize: CGSize {
        if self.mediaCollectionController?.status == .fetching && self.mediaCollectionController?.count != 0 {
            return CGSize(width: self.view.bounds.width, height: 49)
        } else {
            return CGSize()
        }
    }
    
    // MARK: - Actions
    
    @objc fileprivate func refresh(_ sender: AnyObject) {
        self.mediaCollectionController?.fetchInitialContent()
    }
    
    @objc fileprivate func sortingBarItemTapped(_ sortingBar: ScrollableButtonBar) {
        if let index = sortingBar.selectedItemIndex {
            let sortType = self.sortTypeForSortingBarIndex(index)
            if sortType.supportsTimeFrame(.posts) {
                self.showTimeFrameActionSheet(sortType, sortingBar: sortingBar)
            } else {
                let timeFrame: CollectionTimeFrame = sortType == .hot ? .thisMonth : .allTime
                self.changeSorting(sortType, timeFrame: timeFrame)
            }
        }
    }
    
    fileprivate func showTimeFrameActionSheet(_ sortType: CollectionSortType, sortingBar: ScrollableButtonBar) {
        let alertController = BeamAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-hour"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .thisHour)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-24-hours"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .today)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-week"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .thisWeek)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-month"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .thisMonth)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-year"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .thisYear)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("all-time"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .allTime)
        }))
        alertController.addCancelAction { (_) in
            self.sortingBar.selectedItemIndex = self.sortingBarIndexForSortType(self.mediaCollectionController?.sortType ?? .hot)
        }
        
        alertController.popoverPresentationController?.sourceView = sortingBar
        alertController.popoverPresentationController?.sourceRect = sortingBar.buttonFrameForSelectedItemIndex() ?? sortingBar.frame
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func sortingBarIndexForSortType(_ sortType: CollectionSortType) -> Int {
        switch sortType {
        case .hot:
            return 0
        case .new:
            return 1
        case .rising:
            return 2
        case .controversial:
            return 3
        case .top:
            return 4
        default:
            return 0
        }
    }
    
    fileprivate func sortTypeForSortingBarIndex(_ index: Int) -> CollectionSortType {
        switch index {
        case 1:
            return .new
        case 2:
            return .rising
        case 3:
            return .controversial
        case 4:
            return .top
        default:
            return .hot
        }
    }
    
    fileprivate func changeSorting(_ sorting: CollectionSortType, timeFrame: CollectionTimeFrame) {
        self.mediaCollectionController?.setSortingType(sorting, timeFrame: timeFrame)
        self.subreddit?.mediaSortType = sorting
        self.subreddit?.mediaTimeFrame = timeFrame
        
        self.initiallyFetchContent()
    }
    
    // MARK: - Display Mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        //Collectionview sets the backgroundViews color to white when it's set. This is to fix that
        var backgroundView: UIView? = self.collectionView
        if self.collectionView?.backgroundView != nil {
            backgroundView = self.collectionView?.backgroundView
        }
        
        if let backgroundView = backgroundView {
            switch displayMode {
            case .default:
                toolbar.barTintColor = UIColor.beamBarColor()
                backgroundView.backgroundColor = UIColor.groupTableViewBackground
            case .dark:
                backgroundView.backgroundColor = UIColor.beamDarkBackgroundColor()
                toolbar.barTintColor = UIColor.beamDarkContentBackgroundColor()
            }
        }
    }
    
    func galleryViewControllerForPost(_ post: Post, mediaItem: MediaObject) -> AWKGalleryViewController {
        let gallery = AWKGalleryViewController()
        gallery.dataSource = self
        gallery.delegate = self

        let postToolbarXib = UINib(nibName: "GalleryPostBottomView", bundle: nil)
        let toolbar = postToolbarXib.instantiate(withOwner: nil, options: nil).first as? GalleryPostBottomView
        toolbar?.post = post
        toolbar?.toolbarView.delegate = self
        toolbar?.metadataView.delegate = self
        
        let shouldShowSubreddit = (self.subreddit is Multireddit || self.subreddit?.identifier == Subreddit.frontpageIdentifier || self.subreddit?.identifier == Subreddit.allIdentifier) && UserSettings[.showPostMetadataSubreddit] && UserSettings[.showPostMetadata]
        toolbar?.shouldShowSubreddit = shouldShowSubreddit
        
        gallery.bottomView = toolbar
        
        gallery.currentItem = mediaItem.galleryItem
        
        gallery.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_arrow_back"), style: UIBarButtonItemStyle.plain, target: gallery, action: #selector(AWKGalleryViewController.dismissGallery(_:)))
        
        return gallery
    }
}

// MARK: - UICollectionViewDataSource
extension SubredditMediaOverviewViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mediaCollectionController?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let post = self.mediaCollectionController?.itemAtIndexPath(indexPath)
        let cellIdentifier = "media"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! MediaOverviewCollectionViewCell
        cell.isOpaque = false
        cell.mediaObject = post?.mediaObjects?.firstObject as? Snoo.MediaObject
        cell.shouldShowNSFWOverlay = self.subreddit?.shouldShowNSFWOverlay() ?? UserSettings[.showPrivacyOverlay]
        cell.shouldShowSpoilerOverlay = self.subreddit?.shouldShowSpoilerOverlay() ?? UserSettings[.showSpoilerOverlay]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionFooter {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "loader", for: indexPath) as! CollectionViewLoaderFooterView
            return view
        }
        fatalError()
    }
}

// MARK: - UIScrollViewDelegate
extension SubredditMediaOverviewViewController {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        //Determine if the user is in the "load more" scroll region
        if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height && (scrollView.isDragging || scrollView.isDecelerating) {
            self.startLoadingMoreContentIfPossible()
        } else {
            self.hasEnteredLoadMoreState = false
        }
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        self.buttonBarScrollViewDidScrollToTop(scrollView)
    }
    
    func startLoadingMoreContentIfPossible() {
        guard (DataController.shared.redditReachability?.isReachable ?? true) == true else {
            AWKDebugLog("Reddit is not reachable")
            return
        }
        
        guard !(self.hasEnteredLoadMoreState && self.mediaCollectionController?.error != nil) else {
            AWKDebugLog("The user has already tried loading more content but has hit an error. the user has to scroll up again to fix this")
            return
        }
        
        guard self.mediaCollectionController?.moreContentAvailable == true else {
            AWKDebugLog("There isn't any more content to load")
            return
        }
        
        self.hasEnteredLoadMoreState = true
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SubredditMediaOverviewViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let post = self.mediaCollectionController?.itemAtIndexPath(indexPath), let mediaObject = post.mediaObjects?.firstObject as? Snoo.MediaObject {
            let galleryViewController = self.galleryViewControllerForPost(post, mediaItem: mediaObject)
            self.galleryViewController = galleryViewController
            let oldTransitioningDelegate = galleryViewController.transitioningDelegate
            
            let hasAlbumAnimator = post.mediaObjects?.count ?? 0 > 1
            if hasAlbumAnimator {
                galleryViewController.transitioningDelegate = self
            }
            
            self.presentGalleryViewController(galleryViewController, sourceView: collectionView.cellForItem(at: indexPath)?.contentView) { () -> Void in
                galleryViewController.transitioningDelegate = oldTransitioningDelegate
            }
            
            if let count = self.mediaCollectionController?.count, indexPath.row >= count - 5 {
                self.startLoadingMoreContentIfPossible()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return self.footerLoaderSize
    }
    
}

// MARK: - AWKGalleryDataSource
extension SubredditMediaOverviewViewController: AWKGalleryDataSource {
    
    func numberOfItems(inGallery galleryViewController: AWKGalleryViewController) -> Int {
        return self.mediaCollectionController?.count ?? 0
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, itemAt index: UInt) -> AWKGalleryItem {
        let indexPath = IndexPath(item: Int(index), section: 0)
        if let item = self.mediaCollectionController?.itemAtIndexPath(indexPath), let mediaObject = item.mediaObjects?.firstObject as? Snoo.MediaObject {
            return mediaObject.galleryItem
        }
        fatalError()
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, indexOf item: AWKGalleryItem) -> Int {
        if let galleryItem = item as? GalleryItem, let post = galleryItem.mediaObject?.content as? Post, let indexPath = self.mediaCollectionController?.indexPathForCollectionItem(post) {
            return indexPath.item
        }
        return 0
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, contentViewControllerFor item: AWKGalleryItem) -> (UIViewController & AWKGalleryItemContent)? {
        if let image = item as? GalleryItem, let mediaObject = image.mediaObject, let post = mediaObject.content as? Post, (post.mediaObjects?.count ?? 0) > 1 {
            let storyboard = UIStoryboard(name: "MediaOverview", bundle: nil)
            if let albumViewController = storyboard.instantiateViewController(withIdentifier: "gallery-album") as? GalleryAlbumContentViewController {
                albumViewController.galleryViewController = galleryViewController
                albumViewController.post = post
                albumViewController.visibleSubreddit = self.subreddit
                return albumViewController
            }
        }
        return nil
    }
    
}

// MARK: - AWKGalleryDelegate
extension SubredditMediaOverviewViewController: AWKGalleryDelegate {
    
    func gallery(_ galleryViewController: AWKGalleryViewController, presentationAnimationSourceViewFor item: AWKGalleryItem) -> UIView? {
        if let galleryItem = item as? GalleryItem, let post = galleryItem.mediaObject?.content as? Post, let indexPath = self.mediaCollectionController?.indexPathForCollectionItem(post) {
            let cell = collectionView.cellForItem(at: indexPath)  as? MediaOverviewCollectionViewCell
            return cell?.mediaImageView
        }
        return nil
        
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, didScrollFrom item: AWKGalleryItem) {
        
        if let toolbar = galleryViewController.bottomView as? GalleryPostBottomView, let galleryItem = galleryViewController.currentItem as? GalleryItem {
            let post = galleryItem.mediaObject?.content as? Post
            toolbar.post = post
        }
        
        // The current cell always needs to be hidden due to a possible dismissal animation or an alpha background color on the gallery. Unhide the old gallery item.
        
        let fromIndexPath = IndexPath(item: self.gallery(galleryViewController, indexOf: item), section: 0)
        self.collectionView?.cellForItem(at: fromIndexPath)?.contentView.isHidden = false
        
        if let currentItem = galleryViewController.currentItem {
            let itemIndex = self.gallery(galleryViewController, indexOf: currentItem)
            let toIndexPath = IndexPath(item: itemIndex, section: 0)
            self.collectionView?.cellForItem(at: toIndexPath)?.contentView.isHidden = true
            
            if let count = self.mediaCollectionController?.count, itemIndex >= count - 5 {
                self.startLoadingMoreContentIfPossible()
            }
        }
        
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, shouldBeDismissedWithCustomContentViewController viewController: UIViewController & AWKGalleryItemContent) {
        
        let oldTransitioningDelegate = galleryViewController.transitioningDelegate
        
        if viewController is GalleryAlbumContentViewController {
            galleryViewController.transitioningDelegate = self
        }
        
        if let currentItem = galleryViewController.currentItem {
            let indexPath = IndexPath(item: self.gallery(galleryViewController, indexOf: currentItem), section: 0)
        
            self.dismissGalleryViewController(galleryViewController, sourceView: self.collectionView?.cellForItem(at: indexPath)?.contentView) { () -> Void in
                galleryViewController.transitioningDelegate = oldTransitioningDelegate
            }
        }
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, shouldBeDismissedAnimated animated: Bool) {
        if let currentItem = galleryViewController.currentItem {
            let indexPath = IndexPath(item: self.gallery(galleryViewController, indexOf: currentItem), section: 0)
            self.dismissGalleryViewController(galleryViewController, sourceView: self.collectionView?.cellForItem(at: indexPath)?.contentView)
        }
        
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, failedLoading item: AWKGalleryItem, withError error: Error?) {
        
        if let error = error {
            NSLog("Failed to load gallery item: \(error)")
        } else {
            NSLog("Failed to load gallery item with an unknown error.")
        }
        
    }
    
}

extension SubredditMediaOverviewViewController: PostToolbarViewDelegate {
    
    func visibleSubredditForToolbarView(_ toolbarView: PostToolbarView) -> Subreddit? {
        return self.subreddit
    }
    
}

// MARK: - UIViewControllerTransitioningDelegate
extension SubredditMediaOverviewViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if let gallery = presented as? AWKGalleryViewController {
            return animationControllerForGallery(gallery)
        }
        return nil
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if let gallery = dismissed as? AWKGalleryViewController {
            return self.animationControllerForGallery(gallery, dismissal: true)
        }
        return nil
        
    }
    
    func animationControllerForGallery(_ gallery: AWKGalleryViewController, dismissal: Bool = false) -> GalleryAlbumItemAnimator? {
        if let currentItem = gallery.currentItem as? GalleryItem,
            let post = currentItem.mediaObject?.content as? Post,
            let indexPath = self.mediaCollectionController?.indexPathForCollectionItem(post),
            let cell = self.collectionView?.cellForItem(at: indexPath) as? MediaOverviewCollectionViewCell, post.mediaObjects?.count ?? 0 > 0 {
                let animator = GalleryAlbumItemAnimator()
                animator.sourceView = cell.mediaImageView
                animator.dismissal = dismissal
                return animator
        }
        
        return nil
    }
    
}

// MARK: - SubredditMediaCollectionControllerDelegate
extension SubredditMediaOverviewViewController: SubredditMediaCollectionControllerDelegate {
    
    func mediaCollectionController(_ controller: SubredditMediaCollectionController, didChangeCollection collection: [Post]?) {
        DispatchQueue.main.async {
            if self.mediaCollectionController?.count ?? 0 == 0 {
                self.loadingState = BeamViewControllerLoadingState.empty
            } else {
                self.loadingState = BeamViewControllerLoadingState.populated
            }
            
            self.hasEnteredLoadMoreState = false
            self.collectionView?.reloadData()
            self.galleryViewController?.reloadData()
        }
    }
    
    func mediaCollectionController(_ controller: SubredditMediaCollectionController, shouldFetchMoreForCollection collection: [Post]?) -> Bool {
        return self.collectionViewIsFilled == false && self.view.window != nil && (DataController.shared.redditReachability?.isReachable ?? true) == true
    }
    
    func mediaCollectionController(_ controller: SubredditMediaCollectionController, statusDidChange status: CollectionControllerStatus) {
        DispatchQueue.main.async {
            self.flowLayout.invalidateLayout()
            
            if status == .error && self.mediaCollectionController?.count == 0 {
                self.loadingState = BeamViewControllerLoadingState.empty
            }
            
            if status == .error {
                if let error = controller.error as NSError?, error.code == NSURLErrorNotConnectedToInternet && error.domain == NSURLErrorDomain {
                    self.presentErrorMessage(AWKLocalizedString("error-loading-posts-internet"))
                } else {
                    self.presentErrorMessage(AWKLocalizedString("error-loading-posts"))
                }
            }

            if status != .fetching {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func mediaCollectionController(_ controller: SubredditMediaCollectionController, filterCollection collection: [Post]) -> [Post] {
        guard let subreddit = self.subreddit else {
            return collection
        }
        let shouldFilterSubreddits: Bool = subreddit.identifier == Subreddit.allIdentifier
        let filteredContent: [Post] = collection.filter { (content: Post) -> Bool in
            let postTitle: String? = content.title
            let subredditName: String? = content.subreddit?.displayName
            //containsString and length are faster on NSString than on swift string
            if let keywords: [String] = subreddit.filterKeywords, let title: NSString = postTitle?.lowercased() as NSString?, title.length > 0 {
                for filterKeyword: String in keywords {
                    if title.contains(filterKeyword) {
                        //If it contains the keyword, we don't want to continue!
                        return false
                    }
                }
            }
            
            //containsString and length are faster on NSString than on swift string
            if shouldFilterSubreddits {
                if let filterSubreddits: [String] = subreddit.filterSubreddits, let subreddit = subredditName?.lowercased(), subreddit.count > 0 {
                    //If it contains the keyword, we don't want to continue!
                    return !filterSubreddits.contains(where: { (keyword) -> Bool in
                        return subreddit == keyword
                    })
                }
            }
            
            return true
        }
        return filteredContent
    }
    
}

// MARK: - UIToolbarDelegate
extension SubredditMediaOverviewViewController: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
}

// MARK: - NavigationBarNotificationDisplayingDelegate
extension SubredditMediaOverviewViewController: NavigationBarNotificationDisplayingDelegate {
    
    func topViewForDisplayOfnotificationView<NotificationView: UIView>(_ view: NotificationView) -> UIView? where NotificationView: NavigationBarNotification {
        return self.sortingBar.superview
    }
}

@available(iOS 9, *)
extension SubredditMediaOverviewViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = self.collectionView.indexPathForItem(at: location),
            let cell = self.collectionView.cellForItem(at: indexPath),
            let post = self.mediaCollectionController?.itemAtIndexPath(indexPath),
            let mediaObject = post.mediaObjects?.firstObject as? Snoo.MediaObject {
                
                var viewController: UIViewController?
                if cell is MediaOverviewCollectionViewCell {
                    
                    let galleryViewController = self.galleryViewControllerForPost(post, mediaItem: mediaObject)
                    self.galleryViewController = galleryViewController
                    galleryViewController.shouldAutomaticallyDisplaySecondaryViews = false
                    viewController = galleryViewController
                    if let mediaObjects = post.mediaObjects, mediaObjects.count > 1 {
                        viewController?.preferredContentSize = UIScreen.main.bounds.size
                    } else {
                        viewController?.preferredContentSize = mediaObject.viewControllerPreviewingSize()
                    }
                }
                
                //Set the frame to animate the peek from
                previewingContext.sourceRect = cell.frame
                
                //Pass the view controller to display
                return viewController
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let galleryViewController = viewControllerToCommit as? AWKGalleryViewController {
            galleryViewController.shouldAutomaticallyDisplaySecondaryViews = true
            self.presentGalleryViewController(galleryViewController, sourceView: nil)
        }
    }
}
