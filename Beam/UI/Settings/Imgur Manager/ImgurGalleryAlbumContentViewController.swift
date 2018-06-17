//
//  ImgurGalleryAlbumContentViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 28-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import AWKGallery
import ImgurKit

private let reuseIdentifier = "media"

/// The view controller that is visible in AWKGallery as custom content for an album.
class ImgurGalleryAlbumContentViewController: UIViewController, AWKGalleryItemContent {
    
    let imageCountInRow = 3
    
    @IBOutlet fileprivate var collectionView: UICollectionView!
    @IBOutlet fileprivate var collectionViewHeightConstraint: NSLayoutConstraint!
    
    var galleryViewController: AWKGalleryViewController?
    
    var album: ImgurAlbum?
    
    var item: AWKGalleryItem?
    
    var visible = true {
        didSet {
            if self.visible {
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
        let side = view.bounds.width / CGFloat(self.imageCountInRow) - self.flowLayout.minimumInteritemSpacing
        return CGSize(width: side, height: side)
    }
    
    var itemCount: Int {
        return self.album?.images?.count ?? 0
    }
    
    func configureCollectionViewSize() {
        self.collectionViewHeightConstraint.constant = self.view.bounds.height
        
        self.collectionView.contentInset = UIEdgeInsets(top: self.topLayoutGuide.length + 44, left: CGFloat(0), bottom: self.galleryViewController?.galleryBottomLayoutGuide.length ?? 0.0, right: CGFloat(0))
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
        if let image = self.album?.images?[(indexPath as IndexPath).row] {
            let gallery = self.galleryViewControllerForImage(image)
            gallery.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_arrow_back"), style: UIBarButtonItemStyle.plain, target: gallery, action: #selector(AWKGalleryViewController.dismissGallery(_:)))
            
            self.presentGalleryViewController(gallery, sourceView: nil)
        }
        
    }
    
    fileprivate func galleryViewControllerForImage(_ image: ImgurImage) -> AWKGalleryViewController {
        let gallery = AWKGalleryViewController()
        gallery.dataSource = self
        gallery.delegate = self
        gallery.currentItem = image.galleryItem
        return gallery
    }
    
    var firstImageView: UIImageView? {
        if self.album?.images?.count ?? 0 > 0 {
            let cell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? ImgurMediaCollectionViewCell
            return cell?.mediaImageView
        }
        return nil
    }

}

// MARK: - UICollectionViewDataSource
extension ImgurGalleryAlbumContentViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.itemCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ImgurMediaCollectionViewCell {
            
            let image = self.album?.images?[(indexPath as IndexPath).item]
            cell.imgurObject = image
            
            return cell
        }
        
        fatalError("Gallery album content cell should be of class 'PostImageCollectionPartItemCell'")
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ImgurGalleryAlbumContentViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.openGalleryAtIndexPath(indexPath)
    }
    
}

// MARK: - AWKGalleryDataSource
extension ImgurGalleryAlbumContentViewController: AWKGalleryDataSource {
    
    func numberOfItems(inGallery galleryViewController: AWKGalleryViewController) -> Int {
        return self.album?.images?.count ?? 0
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, itemAt index: UInt) -> AWKGalleryItem {
        if let image = self.album?.images?[Int(index)] {
            return image.galleryItem
        }
        fatalError()
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, indexOf item: AWKGalleryItem) -> Int {
        if let galleryItem = item as? ImgurGalleryItem, let image = galleryItem.imgurImage, let index = self.album?.images?.index(of: image) {
            return index
        }
        fatalError()
    }
    
}

// MARK: - AWKGalleryDelegate
extension ImgurGalleryAlbumContentViewController: AWKGalleryDelegate {
    
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
extension ImgurGalleryAlbumContentViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = self.collectionView.indexPathForItem(at: location),
            let cell = self.collectionView.cellForItem(at: indexPath),
            let image = self.album?.images?[(indexPath as IndexPath).item] {
            
            var viewController: UIViewController?
            if cell is PostImageCollectionPartItemCell {
                
                let galleryViewController = self.galleryViewControllerForImage(image)
                galleryViewController.shouldAutomaticallyDisplaySecondaryViews = false
                viewController = galleryViewController
                viewController?.preferredContentSize = image.viewControllerPreviewingSize()
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
