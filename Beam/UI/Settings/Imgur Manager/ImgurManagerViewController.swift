//
//  ImgurManagerViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 28-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import ImgurKit
import AWKGallery

class ImgurManagerViewController: BeamCollectionViewController {
    
    fileprivate var items: [ImgurObject]?
    
    fileprivate let imagesInRow = 3
    
    fileprivate var flowLayout: UICollectionViewFlowLayout {
        return self.collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    fileprivate var itemSize: CGSize {
        let side = view.bounds.width / CGFloat(self.imagesInRow) - self.flowLayout.minimumInteritemSpacing
        return CGSize(width: side, height: side)
    }
    
    var emptyView: BeamEmptyView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.flowLayout.minimumInteritemSpacing = 1
        self.flowLayout.minimumLineSpacing = 1
        
        self.navigationItem.title = AWKLocalizedString("imgur-uploads-title")
        
        self.loadItems()
    }
    
    fileprivate func loadItems() {
        let directories: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsPath: String = directories[0]
        let filePath: String = documentsPath + "/imgur-uploads.plist"
        if let data: Data = try? Data(contentsOf: URL(fileURLWithPath: filePath)), let objects: Set<ImgurObject> = NSKeyedUnarchiver.unarchiveObject(with: data) as? Set<ImgurObject> {
            self.items = Array(objects).reversed()
        } else if let data: Data = try? Data(contentsOf: URL(fileURLWithPath: filePath)), let objects: [ImgurObject] = NSKeyedUnarchiver.unarchiveObject(with: data) as? [ImgurObject] {
            self.items = objects.reversed()
        }
        if let items = self.items, items.count > 0 {
            self.collectionView?.backgroundView = nil
        } else {
            if self.emptyView == nil {
                self.emptyView = BeamEmptyView.emptyView(BeamEmptyViewType.ImgurUploadsNoImages, frame: self.view.bounds)
            }
            self.collectionView?.backgroundView = self.emptyView
        }
        self.collectionView?.reloadData()
    }
    
    fileprivate func galleryViewControllerForItem(_ item: ImgurObject) -> AWKGalleryViewController {
        let gallery = AWKGalleryViewController()
        gallery.dataSource = self
        gallery.delegate = self
        
        let postToolbarXib = UINib(nibName: "ImgurGalleryToolbar", bundle: nil)
        let toolbar = postToolbarXib.instantiate(withOwner: nil, options: nil).first as! ImgurGalleryToolbar
        toolbar.imgurObject = item
        toolbar.delegate = self
        gallery.bottomView = toolbar
        
        gallery.currentItem = item.galleryItem
        
        gallery.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_arrow_back"), style: UIBarButtonItemStyle.plain, target: gallery, action: #selector(AWKGalleryViewController.dismissGallery(_:)))
        
        return gallery
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.emptyView?.frame = self.view.frame
        self.emptyView?.layoutMargins = UIEdgeInsets(top: self.view.safeAreaInsets.top, left: 0, bottom: 0, right: 0)
    }

}

// MARK: - ImgurGalleryToolbarDelegate

extension ImgurManagerViewController: ImgurGalleryToolbarDelegate {
    
    func toolbar(_ toolbar: ImgurGalleryToolbar, didTapDeleteOnImgurObject object: ImgurObject) {
        
        let alertController = BeamAlertController(title: nil, message: AWKLocalizedString("are-you-sure-delete-imgur-\(object is ImgurAlbum ? "album" : "image")"), preferredStyle: UIAlertControllerStyle.actionSheet)
        alertController.addCancelAction()
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("delete-button"), style: UIAlertActionStyle.destructive, handler: { (_) in
            if let album = object as? ImgurAlbum {
                guard let images = album.images, !images.isEmpty else {
                    self.deleteAlbum(album)
                    return
                }
                self.showDeleteAlbumImages(album)
            } else if let image = object as? ImgurImage {
                self.deleteImage(image)
            }
        }))
        self.showViewControllerOnGallery(alertController)

    }
    
    fileprivate func showDeleteAlbumImages(_ album: ImgurAlbum) {
        let alertController = BeamAlertController(title: AWKLocalizedString("delete-imgur-album-images-title"), message: AWKLocalizedString("delete-imgur-album-images-message"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("keep-images-button"), style: UIAlertActionStyle.cancel, handler: { (_) in
            self.deleteAlbum(album, withImages: false)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("delete-images-button"), style: UIAlertActionStyle.destructive, handler: { (_) in
            self.deleteAlbum(album, withImages: true)
        }))
        self.showViewControllerOnGallery(alertController)
    }
    
    fileprivate func showViewControllerOnGallery(_ viewController: UIViewController) {
        if let gallery = self.presentedViewController as? AWKGalleryViewController {
            gallery.present(viewController, animated: true, completion: nil)
        } else if let galleryRootViewController = AppDelegate.shared.galleryWindow?.rootViewController, let topViewController = AppDelegate.topViewController(galleryRootViewController) {
            topViewController.present(viewController, animated: true, completion: nil)
        } else {
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func deleteAlbum(_ album: ImgurAlbum, withImages: Bool = false) {
        guard album.deleteHash != nil else {
            return
        }
        self.dismissGallery()
        
        var requests = [ImgurRequest]()
        if let images = album.images, images.count > 0 && withImages == true {
            for image in images {
                guard let deleteHash = image.deleteHash else { continue }
                requests.append(ImgurImageRequest(deleteRequestWithDeleteHash: deleteHash))
            }
        }

        requests.append(ImgurAlbumRequest(deleteRequestWithDeleteHash: album.deleteHash!))
        AppDelegate.shared.imgurController.executeRequests(requests, uploadProgressHandler: nil, completionHandler: { (error) in
            DispatchQueue.main.async(execute: {
                let sucessfulRequests = requests.filter({ $0.error == nil })
                let hashes = sucessfulRequests.map({ return $0.deleteHash! })
                self.removeObjectsWithHashes(hashes)
            })
        })

    }
    
    fileprivate func deleteImage(_ image: ImgurImage) {
        guard image.deleteHash != nil else {
            return
        }
        self.dismissGallery()
        
        let requests = [ImgurImageRequest(deleteRequestWithDeleteHash: image.deleteHash!)]
        
        AppDelegate.shared.imgurController.executeRequests(requests, uploadProgressHandler: nil, completionHandler: { (error) in
            DispatchQueue.main.async(execute: {
                let sucessfulRequests = requests.filter({ $0.error == nil })
                let hashes = sucessfulRequests.map({ return $0.deleteHash! })
                self.removeObjectsWithHashes(hashes)
            })
        })
        
    }
    
    func removeObjectsWithHashes(_ hashes: [String]) {
        for hash in hashes {
            guard let item = self.items?.first(where: { (object) -> Bool in
                return object.deleteHash == hash
            }) else {
                continue
            }
            if let image = item as? ImgurImage {
                //Remove the images from albums
                if let albums = self.items?.filter({ $0 is ImgurAlbum }) as? [ImgurAlbum] {
                    for album in albums {
                        if let index = album.images?.index(of: image) {
                            album.images?.remove(at: index)
                        }
                    }
                }
            }
            if let index = self.items?.index(of: item) {
                self.items?.remove(at: index)
            }
        }
        
        DispatchQueue.main.async {
            self.saveUploadedObjects()
            self.loadItems()
            self.collectionView?.reloadData()
        }
        
    }
    
    func saveUploadedObjects() {
        guard let items = self.items else {
            return
        }
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = documentsPath + "/imgur-uploads.plist"
        if NSKeyedArchiver.archiveRootObject(items.reversed(), toFile: filePath) {
            print("Saved uploads")
        } else {
            print("Failed to save uploads")
        }

    }
    
    fileprivate func dismissGallery() {
        var galleryViewController: AWKGalleryViewController?
        if let galleryRootViewController = AppDelegate.shared.galleryWindow?.rootViewController as? AWKGalleryViewController {
            galleryViewController = galleryRootViewController
        } else if let galleryRootViewController = AppDelegate.shared.galleryWindow?.rootViewController?.presentedViewController as? AWKGalleryViewController {
            galleryViewController = galleryRootViewController
        } else if let galleryRootViewController = AppDelegate.shared.galleryWindow?.rootViewController, let topViewController = AppDelegate.topViewController(galleryRootViewController) as? AWKGalleryViewController {
            galleryViewController = topViewController
        }
        if let galleryViewController = galleryViewController {
            var sourceView: UIView?
            if let item = galleryViewController.currentItem as? ImgurGalleryItem,
            let object = item.imgurObject,
            let index = self.items?.index(of: object),
            let cell = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? ImgurMediaCollectionViewCell {
                sourceView = cell.mediaImageView
            }
            self.dismissGalleryViewController(galleryViewController, sourceView: sourceView, completionHandler: nil)
        }
    }
    
}

// MARK: - UICollectionViewDataSource
extension ImgurManagerViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = self.items?[(indexPath as IndexPath).row]
        let cellIdentifier = "media"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ImgurMediaCollectionViewCell
        cell.isOpaque = false
        cell.imgurObject = item
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ImgurManagerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.items?[(indexPath as IndexPath).row] else {
            return
        }
        let galleryViewController = self.galleryViewControllerForItem(item)
        let oldTransitioningDelegate = galleryViewController.transitioningDelegate
        
        if item is ImgurAlbum {
            galleryViewController.transitioningDelegate = self
        }
        
        var sourceView: UIView?
        if let mediaCell = self.collectionView?.cellForItem(at: indexPath) as? ImgurMediaCollectionViewCell {
            sourceView = mediaCell.mediaImageView
        }
        self.presentGalleryViewController(galleryViewController, sourceView: sourceView) { () -> Void in
            galleryViewController.transitioningDelegate = oldTransitioningDelegate
        }
    }
    
}

extension ImgurManagerViewController: AWKGalleryDelegate {

    func gallery(_ galleryViewController: AWKGalleryViewController, presentationAnimationSourceViewFor item: AWKGalleryItem) -> UIView? {
        if let galleryItem = item as? ImgurGalleryItem, let item = galleryItem.imgurObject, let index = self.items?.index(of: item) {
            let indexPath = IndexPath(item: index, section: 0)
            let cell = collectionView?.cellForItem(at: indexPath) as? ImgurMediaCollectionViewCell
            return cell?.mediaImageView
        }
        return nil
        
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, didScrollFrom item: AWKGalleryItem) {
        
        if let toolbar = galleryViewController.bottomView as? ImgurGalleryToolbar, let galleryItem = galleryViewController.currentItem as? ImgurGalleryItem {
            toolbar.imgurObject = galleryItem.imgurObject
        }
        
        // The current cell always needs to be hidden due to a possible dismissal animation or an alpha background color on the gallery. Unhide the old gallery item.
        
        let fromIndexPath = IndexPath(item: self.gallery(galleryViewController, indexOf: item), section: 0)
        if let mediaCell = self.collectionView?.cellForItem(at: fromIndexPath) as? ImgurMediaCollectionViewCell {
            mediaCell.mediaImageView.isHidden = false
        }
        
        if let currentItem = galleryViewController.currentItem {
            let itemIndex = self.gallery(galleryViewController, indexOf: currentItem)
            let toIndexPath = IndexPath(item: itemIndex, section: 0)
            if let mediaCell = self.collectionView?.cellForItem(at: toIndexPath) as? ImgurMediaCollectionViewCell {
                mediaCell.mediaImageView.isHidden = true
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
            
            var sourceView: UIView?
            if let mediaCell = self.collectionView?.cellForItem(at: indexPath) as? ImgurMediaCollectionViewCell {
                sourceView = mediaCell.mediaImageView
            }
            self.dismissGalleryViewController(galleryViewController, sourceView: sourceView) { () -> Void in
                galleryViewController.transitioningDelegate = oldTransitioningDelegate
            }
        }
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, shouldBeDismissedAnimated animated: Bool) {
        if let currentItem = galleryViewController.currentItem {
            let indexPath = IndexPath(item: self.gallery(galleryViewController, indexOf: currentItem), section: 0)
            var sourceView: UIView?
            if let mediaCell = self.collectionView?.cellForItem(at: indexPath) as? ImgurMediaCollectionViewCell {
                sourceView = mediaCell.mediaImageView
            }
            self.dismissGalleryViewController(galleryViewController, sourceView: sourceView)
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

extension ImgurManagerViewController: AWKGalleryDataSource {
    
    func numberOfItems(inGallery galleryViewController: AWKGalleryViewController) -> Int {
        return self.items?.count ?? 0
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, itemAt index: UInt) -> AWKGalleryItem {
        if let item = self.items?[Int(index)] {
            return item.galleryItem
        }
        fatalError()
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, indexOf item: AWKGalleryItem) -> Int {
        if let galleryItem = item as? ImgurGalleryItem, let item = galleryItem.imgurObject, let index = self.items?.index(of: item) {
            return index
        }
        return 0
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, contentViewControllerFor item: AWKGalleryItem) -> (UIViewController & AWKGalleryItemContent)? {
        if let galleryItem = item as? ImgurGalleryItem, let album = galleryItem.imgurObject as? ImgurAlbum {
            let storyboard = UIStoryboard(name: "MediaOverview", bundle: nil)
            if let albumViewController = storyboard.instantiateViewController(withIdentifier: "imgur-gallery-album") as? ImgurGalleryAlbumContentViewController {
                albumViewController.galleryViewController = galleryViewController
                albumViewController.album = album
                return albumViewController
            }
        }
        return nil
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension ImgurManagerViewController: UIViewControllerTransitioningDelegate {
    
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
        if let currentItem = gallery.currentItem as? ImgurGalleryItem,
            let album = currentItem.imgurObject as? ImgurAlbum,
            let index = self.items?.index(of: album) {
            if let cell = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? ImgurMediaCollectionViewCell {
                let animator = GalleryAlbumItemAnimator()
                animator.sourceView = cell.mediaImageView
                animator.dismissal = dismissal
                return animator
            }
        }
        
        return nil
    }
    
}
