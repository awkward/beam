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

private enum PostMediaOverviewViewControllerLayout: Int {
    case list = 0
    case grid = 1
}

class PostMediaOverviewViewController: BeamCollectionViewController, PostMetadataViewDelegate {
    
    fileprivate let imagesInRow: CGFloat = 3
    
    var mediaCollectionController = PostMediaCollectionController()
    
    // View
    fileprivate var flowLayout: UICollectionViewFlowLayout {
        return self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    fileprivate var layout: PostMediaOverviewViewControllerLayout = .grid {
        didSet {
            configureNavigationItem()
            reloadCollectionViewLayoutAnimated(false)
        }
    }
    
    // Content
    var post: Post? {
        didSet {
            self.mediaCollectionController.post = post
            self.collectionView?.reloadData()
        }
    }
    var visibleSubreddit: Subreddit? {
        didSet {
            self.collectionView?.reloadData()
        }
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reloadCollectionViewLayoutAnimated(false)
        
        if let collectioNView = self.collectionView {
            self.registerForPreviewing(with: self, sourceView: collectioNView)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.layout = PostMediaOverviewViewControllerLayout(rawValue: UserSettings[.postMediaOverViewLayout])!
    }
    
    // MARK: - Layout
    
    func configureNavigationItem() {
        switch layout {
        case .list:
            navigationItem.setRightBarButton(UIBarButtonItem(image: UIImage(named: "view_mode_grid"), style: .plain, target: self, action: #selector(PostMediaOverviewViewController.layoutButtonTapped(_:))), animated: true)
        case .grid:
            navigationItem.setRightBarButton(UIBarButtonItem(image: UIImage(named: "view_mode_list"), style: .plain, target: self, action: #selector(PostMediaOverviewViewController.layoutButtonTapped(_:))), animated: true)
        }
    }
    
    @IBAction func layoutButtonTapped(_ sender: UIBarButtonItem) {
        switch layout {
        case .list:
            layout = .grid
        case .grid:
            layout = .list
        }
        UserSettings[.postMediaOverViewLayout] = self.layout.rawValue
    }
    
    fileprivate func reloadCollectionViewLayoutAnimated(_ animated: Bool) {
        let newLayout = UICollectionViewFlowLayout()
        
        switch layout {
        case .list:
            newLayout.sectionInset = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
            newLayout.minimumLineSpacing = 13
        case .grid:
            newLayout.minimumInteritemSpacing = 1
            newLayout.minimumLineSpacing = 1
        }
        
        collectionView?.setCollectionViewLayout(newLayout, animated: animated, completion: { (_) -> Void in
            self.collectionView?.reloadData()
        })
    
        if self.mediaCollectionController.count > 0 {
            collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: UICollectionViewScrollPosition.top, animated: false)
        }
    }
    
    func galleryViewControllerForPost(_ post: Post, mediaItem: MediaObject) -> AWKGalleryViewController {
        let gallery = AWKGalleryViewController()
        gallery.dataSource = self
        gallery.delegate = self
        gallery.displaysNavigationItemCount = true
        
        gallery.currentItem = mediaItem.galleryItem

        gallery.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_arrow_back"), style: UIBarButtonItemStyle.plain, target: gallery, action: #selector(AWKGalleryViewController.dismissGallery(_:)))
        
        let postToolbarXib = UINib(nibName: "GalleryPostBottomView", bundle: nil)
        let toolbar = postToolbarXib.instantiate(withOwner: nil, options: nil).first as? GalleryPostBottomView
        toolbar?.post = post
        toolbar?.toolbarView.delegate = self
        toolbar?.metadataView.delegate = self
        gallery.bottomView = toolbar
        return gallery
    }
    
}

// MARK: - UICollectionViewDataSource
extension PostMediaOverviewViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mediaCollectionController.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let mediaObject = self.mediaCollectionController.itemAtIndexPath(indexPath)
        let cellIdentifier = (self.layout == .list) ? "mediacaption" : "media"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! MediaOverviewCollectionViewCell
        cell.isOpaque = true
        cell.mediaObject = mediaObject
        cell.shouldShowNSFWOverlay = self.visibleSubreddit?.shouldShowNSFWOverlay() ?? UserSettings[.showPrivacyOverlay]
        cell.shouldShowSpoilerOverlay = self.visibleSubreddit?.shouldShowSpoilerOverlay() ?? UserSettings[.showSpoilerOverlay]
        return cell
    }
    
}

extension PostMediaOverviewViewController: PostToolbarViewDelegate {
    
    func visibleSubredditForToolbarView(_ toolbarView: PostToolbarView) -> Subreddit? {
        return self.visibleSubreddit
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PostMediaOverviewViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let mediaObject = self.mediaCollectionController.itemAtIndexPath(indexPath), layout == .list {
            let sectionInset = flowLayout.sectionInset
            let imageWidth = collectionView.bounds.width - sectionInset.left - sectionInset.right
            let imageHeight = imageWidth / self.imagesInRow * (self.imagesInRow - 1)
            let content = MediaOverviewCollectionViewCell.attributedContentForMediaObject(mediaObject)
            let contentHeight = (content != nil) ? MediaOverviewCollectionViewCell.heightForMetaData(content!, constrainingSize: CGSize(width: collectionView.bounds.width, height: CGFloat.greatestFiniteMagnitude)) : 0
            return CGSize(width: imageWidth, height: imageHeight + contentHeight)
        } else {
            let side = view.bounds.width / self.imagesInRow - flowLayout.minimumInteritemSpacing
            return CGSize(width: side, height: side)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let post = self.post, let mediaObject = self.mediaCollectionController.itemAtIndexPath(indexPath) {
            let gallery = self.galleryViewControllerForPost(post, mediaItem: mediaObject)
            self.presentGalleryViewController(gallery, sourceView: collectionView.cellForItem(at: indexPath)?.contentView)
        }
    }
    
}

// MARK: - AWKGalleryDataSource
extension PostMediaOverviewViewController: AWKGalleryDataSource {
    
    func numberOfItems(inGallery galleryViewController: AWKGalleryViewController) -> Int {
        return self.mediaCollectionController.count
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, itemAt index: UInt) -> AWKGalleryItem {
        
        let indexPath = IndexPath(item: Int(index), section: 0)
        if let item = self.mediaCollectionController.itemAtIndexPath(indexPath)?.galleryItem {
            return item
        }
        fatalError()
        
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, indexOf item: AWKGalleryItem) -> Int {
        if let item = item as? GalleryItem, let mediaObject = item.mediaObject, let indexPath = self.mediaCollectionController.indexPathForCollectionItem(mediaObject) {
            return indexPath.item
        }
        fatalError()
    }
    
}

// MARK: - AWKGalleryDelegate
extension PostMediaOverviewViewController: AWKGalleryDelegate {
    
    func gallery(_ galleryViewController: AWKGalleryViewController, presentationAnimationSourceViewFor item: AWKGalleryItem) -> UIView? {
        
        let indexPath = IndexPath(item: gallery(galleryViewController, indexOf: item), section: 0)
        let cell = collectionView?.cellForItem(at: indexPath) as? MediaOverviewCollectionViewCell
        return cell?.mediaImageView
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, didScrollFrom item: AWKGalleryItem) {
        
        // The current cell always needs to be hidden due to a possible dismissal animation or an alpha background color on the gallery. Unhide the old gallery item.
        
        let fromIndexPath = IndexPath(item: self.gallery(galleryViewController, indexOf: item), section: 0)
        self.collectionView?.cellForItem(at: fromIndexPath)?.contentView.isHidden = false
        
        if let currentItem = galleryViewController.currentItem {
            let toIndexPath = IndexPath(item: self.gallery(galleryViewController, indexOf: currentItem), section: 0)
            self.collectionView?.cellForItem(at: toIndexPath)?.contentView.isHidden = true
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

@available(iOS 9, *)
extension PostMediaOverviewViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = self.collectionView?.indexPathForItem(at: location),
            let cell = self.collectionView?.cellForItem(at: indexPath),
            let mediaObject = self.mediaCollectionController.itemAtIndexPath(indexPath),
            let post = self.post {
                
                var viewController: UIViewController?
                if cell is MediaOverviewCollectionViewCell {
                    
                    let galleryViewController = self.galleryViewControllerForPost(post, mediaItem: mediaObject)
                    galleryViewController.shouldAutomaticallyDisplaySecondaryViews = false
                    viewController = galleryViewController
                    viewController?.preferredContentSize = mediaObject.viewControllerPreviewingSize()
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
