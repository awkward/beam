//
//  GalleryAlbumContentViewController.swift
//  beam
//
//  Created by Robin Speijer on 09-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import AWKGallery

private let reuseIdentifier = "image"

/// The view controller that is visible in AWKGallery as custom content for an album.
class GalleryAlbumContentViewController: UIViewController, AWKGalleryItemContent {
    
    let imageCountInRow = 3
    
    @IBOutlet fileprivate var collectionView: UICollectionView!
    @IBOutlet fileprivate var collectionViewHeightConstraint: NSLayoutConstraint!
    
    var galleryViewController: AWKGalleryViewController?
    
    var post: Post? {
        didSet {
            self.mediaCollectionController = PostMediaCollectionController()
            self.mediaCollectionController?.post = self.post
        }
    }
    var visibleSubreddit: Subreddit?
    
    var mediaCollectionController: PostMediaCollectionController?
    
    var item: AWKGalleryItem?
    
    var visible = true {
        didSet {
            if visible {
                self.collectionView.reloadData()
            }
        }
    }
    
    var contentView: UIView {
        return self.collectionView
    }
    
    var flowLayout: UICollectionViewFlowLayout {
        return self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    var itemSize: CGSize {
        let side = view.bounds.width / CGFloat(imageCountInRow) - self.flowLayout.minimumInteritemSpacing
        return CGSize(width: side, height: side)
    }
    
    var itemCount: Int {
        return self.post?.mediaObjects?.count ?? 0
    }
    
    func configureCollectionViewSize() {
        self.collectionViewHeightConstraint.constant = self.view.bounds.height
        
        self.collectionView.contentInset = UIEdgeInsets(top: 44, left: CGFloat(0), bottom: self.galleryViewController?.galleryBottomLayoutGuide.length ?? 0.0, right: CGFloat(0))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.registerForPreviewing(with: self, sourceView: self.collectionView)
    }

    override func updateViewConstraints() {
        self.configureCollectionViewSize()
        super.updateViewConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.configureCollectionViewSize()
    }
    
    fileprivate func openGalleryAtIndexPath(_ indexPath: IndexPath) {
        if let mediaObject = self.mediaCollectionController?.itemAtIndexPath(indexPath) {
            let gallery = self.galleryViewControllerForMediaItem(mediaObject)
            gallery.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_arrow_back"), style: .plain, target: gallery, action: #selector(AWKGalleryViewController.dismissGallery(_:)))
        
            self.presentGalleryViewController(gallery, sourceView: nil)
        }

    }
    
    fileprivate func galleryViewControllerForMediaItem( _ mediaItem: MediaObject) -> AWKGalleryViewController {
        let gallery = AWKGalleryViewController()
        gallery.dataSource = self
        gallery.delegate = self
        gallery.currentItem = mediaItem.galleryItem
        return gallery
    }
    
    var firstImageView: UIImageView? {
        if self.mediaCollectionController?.count ?? 0 > 0 {
            let cell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? MediaOverviewCollectionViewCell
            return cell?.mediaImageView
        }
        return nil
    }
    
}

// MARK: - UICollectionViewDataSource
extension GalleryAlbumContentViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.itemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? GalleryAlbumContentItemCell {
            
            let mediaObject = self.post?.mediaObjects?[indexPath.item] as? MediaObject
            cell.mediaObject = mediaObject

            if (indexPath as IndexPath).item == (self.itemCount - 1) {
                cell.moreCount = (self.post?.mediaObjects?.count ?? 0) - self.itemCount
            } else {
                cell.moreCount = 0
            }
            
            cell.shouldShowNSFWOverlay = self.visibleSubreddit?.shouldShowNSFWOverlay() ?? UserSettings[.showPrivacyOverlay]
            cell.shouldShowSpoilerOverlay = self.visibleSubreddit?.shouldShowSpoilerOverlay() ?? UserSettings[.showSpoilerOverlay]
            
            return cell
        }
        
        fatalError("Gallery album content cell should be of class 'PostImageCollectionPartItemCell'")
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout

extension GalleryAlbumContentViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.openGalleryAtIndexPath(indexPath)
    }
    
}

// MARK: - AWKGalleryDataSource
extension GalleryAlbumContentViewController: AWKGalleryDataSource {
    
    func numberOfItems(inGallery galleryViewController: AWKGalleryViewController) -> Int {
        return self.mediaCollectionController?.count ?? 0
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, itemAt index: UInt) -> AWKGalleryItem {
        if let image = self.mediaCollectionController?.itemAtIndexPath(IndexPath(item: Int(index), section: 0))?.galleryItem {
            return image
        } else {
            fatalError()
        }
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, indexOf item: AWKGalleryItem) -> Int {
        if let galleryItem = item as? GalleryItem, let mediaObject = galleryItem.mediaObject, let indexPath = self.mediaCollectionController?.indexPathForCollectionItem(mediaObject) {
            return indexPath.item
        }
        fatalError()
    }
    
}

// MARK: - AWKGalleryDelegate
extension GalleryAlbumContentViewController: AWKGalleryDelegate {
    
    func gallery(_ galleryViewController: AWKGalleryViewController, presentationAnimationSourceViewFor item: AWKGalleryItem) -> UIView? {
        
        let indexPath = IndexPath(item: gallery(galleryViewController, indexOf: item), section: 0)
        let cell = collectionView?.cellForItem(at: indexPath) as? PostImageCollectionPartItemCell
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
extension GalleryAlbumContentViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = self.collectionView.indexPathForItem(at: location),
            let cell = self.collectionView.cellForItem(at: indexPath),
            let mediaObject = self.mediaCollectionController?.itemAtIndexPath(indexPath) {
                
                var viewController: UIViewController?
                if cell is PostImageCollectionPartItemCell {
                    
                    let galleryViewController = self.galleryViewControllerForMediaItem(mediaObject)
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
