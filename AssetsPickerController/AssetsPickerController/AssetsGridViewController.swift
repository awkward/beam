//
//  AssetsGridViewController.swift
//  AWKImagePickerController
//
//  Created by Rens Verhoeven on 27-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

class AssetsGridViewController: UICollectionViewController, AssetsPickerViewController, ColorPaletteSupport {
    
    weak var assetsPickerController: AssetsPickerController? {
        didSet {
            self.startColorPaletteSupport()
        }
    }
    
    fileprivate var showCameraButton: Bool {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            return false
        }
        return self.assetsPickerController!.showCameraOption
    }
    
    var album: Album! {
        didSet {
            self.title = self.assetsPickerController?.delegate?.assetsPickerController(self.assetsPickerController!, navigationBarTitleForAlbum: self.album.title)
            self.startFetchingAssets()
        }
    }
    
    var emptyView: UIView? {
        didSet {
            self.emptyView?.layoutMargins = UIEdgeInsets(top: self.topLayoutGuide.length + 20, left: 20, bottom: self.bottomLayoutGuide.length + 20, right: 20)
            self.collectionView?.backgroundView = self.emptyView
        }
    }
    
    fileprivate let thumbnailCachingManager: PHCachingImageManager = {
        let manager = PHCachingImageManager()
        manager.allowsCachingHighQualityImages = false
        return manager
    }()
    
    fileprivate var thumbnailImageSize = CGSize(width: 100, height: 100) {
        willSet {
            if newValue != self.thumbnailImageSize {
                self.stopCachingThumbnails()
            }
        }
        didSet {
            if oldValue != self.thumbnailImageSize {
                self.startCachingThumbnails()
            }
        }
    }
    
    var numberOfCells: Int {
        return (self.assets?.count ?? 0) + (self.showCameraButton ? 1 : 0)
    }
    
    // MARK: - Assets
    
    fileprivate var assets: [PHAsset]? {
        willSet {
            if let assets = self.assets, let newValue = newValue, newValue != assets {
                self.stopCachingThumbnails()
            }
        }
        didSet {
            if let assets = self.assets, let oldValue = oldValue, oldValue != assets {
                self.startCachingThumbnails()
            }
            DispatchQueue.main.async {
                UIView.performWithoutAnimation({
                    self.collectionView?.reloadSections(IndexSet(integer: 0))
                    for selectedAsset in self.selectedAssets {
                        if let index = self.assets?.index(of: selectedAsset) {
                            self.collectionView?.selectItem(at: IndexPath(item: index + (self.showCameraButton ? 1 : 0), section: 0), animated: false, scrollPosition: UICollectionViewScrollPosition())
                        }
                    }
                })
            }
        }
    }
    
    var selectedAssets = [PHAsset]()
    
    func assetForIndexPath(_ indexPath: IndexPath) -> PHAsset? {
        guard self.assets?.count != 0 else {
            return nil
        }
        if (indexPath as NSIndexPath).row == 0 && self.showCameraButton {
            return nil
        }
        let index = (indexPath as NSIndexPath).row - (self.showCameraButton ? 1 : 0)
        guard let assets = self.assets, index < assets.count && index >= 0 else {
            return nil
        }
        return assets[index]
    }
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView?.allowsMultipleSelection = true

        if self.navigationController is AssetsPickerNavigationController {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(AssetsGridViewController.doneTapped(_:)))
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(AssetsGridViewController.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.navigationController is AssetsPickerNavigationController {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(AssetsGridViewController.doneTapped(_:)))
        }
    }
    
    deinit {
        self.stopColorPaletteSupport()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    @objc fileprivate func doneTapped(_ sender: AnyObject) {
        let selectedAssets = self.selectedAssets
        if selectedAssets.count > 0 {
            self.finishImagePickingWithAssets(selectedAssets)
        } else {
            self.cancelImagePicking()
        }
    }
    
    // MARK: Fetching
    
    fileprivate func startFetchingAssets() {
        guard self.assetsPickerController != nil else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = self.assetsPickerController!.fetchOptions
            var result: PHFetchResult<PHAsset>!
            if let collection = self.album.collection {
                result = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            } else {
                result = PHAsset.fetchAssets(with: fetchOptions)
            }
            var allAssets = [PHAsset]()
            result.enumerateObjects({ (asset, _, _) in
                allAssets.append(asset)
            })
            DispatchQueue.main.async {
                
                self.emptyView = allAssets.count == 0 ? self.assetsPickerController?.delegate?.assetsPickerController(self.assetsPickerController!, emptyViewForAlbum: self.album.title) : nil

                self.assets = allAssets
            }
        }
        
    }
    
    @objc fileprivate func applicationDidBecomeActive(_ notification: Notification) {
        self.startFetchingAssets()
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.numberOfCells
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let asset = self.assetForIndexPath(indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCollectionViewCell.reuseIdentifier, for: indexPath) as! AssetCollectionViewCell
            cell.assetsPickerController = self.assetsPickerController
            cell.imageSize = self.thumbnailImageSize
            cell.imageManager = self.thumbnailCachingManager
            cell.asset = asset
            cell.reloadContents()
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraCollectionViewCell.reuseIdentifier, for: indexPath) as! CameraCollectionViewCell
            cell.assetsPickerController = self.assetsPickerController
            return cell
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let asset = self.assetForIndexPath(indexPath) {
            if !self.selectedAssets.contains(asset) {
                self.selectedAssets.append(asset)
            }
        } else {
            let cameraController = UIImagePickerController()
            cameraController.sourceType = UIImagePickerControllerSourceType.camera
            cameraController.delegate = self
            self.present(cameraController, animated: true, completion: nil)
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let asset = self.assetForIndexPath(indexPath) {
            if self.selectedAssets.contains(asset) {
                self.selectedAssets.remove(at: self.selectedAssets.index(of: asset)!)
            }
        }
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.emptyView?.layoutMargins = UIEdgeInsets(top: self.topLayoutGuide.length + 20, left: 20, bottom: self.bottomLayoutGuide.length + 20, right: 20)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateCollectionViewLayout()
    }
    
    fileprivate func updateCollectionViewLayout() {
        var numberOfColumns: CGFloat = 3
        if self.view.frame.width >= 480 {
            numberOfColumns = 7
        }
        let spacing: CGFloat = 1
        let cellWidth = floor((self.view.frame.width - (spacing * numberOfColumns - 1)) / numberOfColumns)
        if let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            self.thumbnailImageSize = CGSize(width: cellWidth, height: cellWidth)
            flowLayout.itemSize = self.thumbnailImageSize
            flowLayout.minimumInteritemSpacing = spacing
            flowLayout.minimumLineSpacing = spacing
        }
        
    }
    
    // MARK: - Thumbnail caching
    
    fileprivate func stopCachingThumbnails() {
//        self.thumbnailCachingManager.stopCachingImagesForAllAssets()
    }
    
    fileprivate func startCachingThumbnails() {
        //Caching is disabled for now!
//        if let assets = self.assets {
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
//                let options = PHImageRequestOptions()
//                self.thumbnailCachingManager.startCachingImagesForAssets(assets, targetSize: self.thumbnailImageSize, contentMode: PHImageContentMode.AspectFill, options: options)
//            })
//
//        }
    }
    
    // MARK: Color palette support
    
    func colorPaletteDidChange() {
        self.view.backgroundColor = self.colorPalette.backgroundColor
        self.collectionView?.backgroundColor = self.colorPalette.backgroundColor
    }

}

extension AssetsGridViewController: UIImagePickerControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String: AnyObject]?) {
        //Save the image
        var localIdentifier: String?
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
        }, completionHandler: { (_, error) in
            DispatchQueue.main.async(execute: {
                if let error = error {
                    NSLog("Error performing changes \(error)")
                } else {
                    if let localIdentifier = localIdentifier, let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject {
                        NSLog("Adding asset \(asset)")
                        self.selectedAssets.append(asset)
                        self.assets?.insert(asset, at: 0)
                        
                    } else {
                        self.startFetchingAssets()
                    }
                }
            })
        })
        picker.dismiss(animated: true, completion: nil)
    }
}

extension AssetsGridViewController: UINavigationControllerDelegate {
    
}
