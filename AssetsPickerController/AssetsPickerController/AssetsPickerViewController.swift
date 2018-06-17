//
//  ImagePickerViewController.swift
//  AWKImagePickerControllerExample
//
//  Created by Rens Verhoeven on 29-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

internal protocol AssetsPickerViewController {
    
    var assetsPickerController: AssetsPickerController? { get set }
    
    func finishImagePickingWithAssets(_ assets: [PHAsset])
    func cancelImagePicking()
    
}

extension AssetsPickerViewController where Self: UIViewController {

    func finishImagePickingWithAssets(_ assets: [PHAsset]) {
        if let controller = self.assetsPickerController {
            controller.delegate?.assetsPickerController(controller, navigationController: self.navigationController!, didSelectAssets: assets)
        }
    }
    
    func cancelImagePicking() {
        if let controller = self.assetsPickerController {
            controller.delegate?.assetsPickerControllerDidCancel(controller, navigationController: self.navigationController!)
        }
        
    }
}
