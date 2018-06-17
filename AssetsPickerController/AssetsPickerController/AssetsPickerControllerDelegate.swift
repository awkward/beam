//
//  AssetsPickerControllerDelegate.swift
//  AWKImagePickerController
//
//  Created by Rens Verhoeven on 27-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

public protocol AssetsPickerControllerDelegate: class {

    func assetsPickerController(_ assetsPickerController: AssetsPickerController, navigationController: UINavigationController, didSelectAssets assets: [PHAsset])
    func assetsPickerControllerDidCancel(_ assetsPickerController: AssetsPickerController, navigationController: UINavigationController)
    
    func assetsPickerController(_ assetsPickerController: AssetsPickerController, viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView?
    func assetsPickerController(_ assetsPickerController: AssetsPickerController, emptyViewForAlbum albumTitle: String) -> UIView?
    
    func assetsPickerController(_ assetsPickerController: AssetsPickerController, navigationBarTitleForAlbum albumTitle: String) -> String?
    func assetsPickerController(_ assetsPickerController: AssetsPickerController, navigationBarTitleForAlbumsView numberOfAlbums: Int?) -> String?
}

extension AssetsPickerControllerDelegate {
    
    public func assetsPickerControllerDidCancel(_ assetsPickerController: AssetsPickerController, navigationController: UINavigationController) {
        navigationController.dismiss(animated: true, completion: nil)
    }
    
    public func assetsPickerController(_ assetsPickerController: AssetsPickerController, viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView? {
        return UINib(nibName: "NoAccessEmptyView", bundle: Bundle(for: AssetsPickerController.self)).instantiate(withOwner: nil, options: nil).first as? UIView
    }
    
    public func assetsPickerController(_ assetsPickerController: AssetsPickerController, emptyViewForAlbum albumTitle: String) -> UIView? {
        return UINib(nibName: "EmptyAlbumEmptyView", bundle: Bundle(for: AssetsPickerController.self)).instantiate(withOwner: nil, options: nil).first as? UIView
    }
    
    public func assetsPickerController(_ assetsPickerController: AssetsPickerController, navigationBarTitleForAlbum albumTitle: String) -> String? {
        return nil
    }
    
    public func assetsPickerController(_ assetsPickerController: AssetsPickerController, navigationBarTitleForAlbumsView numberOfAlbums: Int?) -> String? {
        return nil
    }
    
}
