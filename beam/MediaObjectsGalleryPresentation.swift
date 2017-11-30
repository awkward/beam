//
//  MediaObjectsGalleryPresentation.swift
//  Beam
//
//  Created by Rens Verhoeven on 30/01/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CherryKit
import AWKGallery

protocol MediaObjectsGalleryPresentation: class, AWKGalleryDataSource, AWKGalleryDelegate {
    
    var galleryMediaObjects: [MediaObject]? { get set }
    
    func presentGallery(with mediaObjects: [MediaObject])
    func presentGallery(with mediaObjects: [MediaObject], initialMediaIndex: Int, post: Post?, sourceView: UIImageView?)
    func galleryViewController(for mediaObject: MediaObject, post: Post?) -> AWKGalleryViewController
    
    func bottomView(for gallery: AWKGalleryViewController, post: Post?) -> UIView?
    
}

extension MediaObjectsGalleryPresentation where Self: UIViewController {
    
    func presentGallery(with mediaObjects: [MediaObject]) {
        self.presentGallery(with: mediaObjects, initialMediaIndex: 0, post: nil, sourceView: nil)
    }
    
    func presentGallery(with mediaObjects: [MediaObject], initialMediaIndex: Int, post: Post?, sourceView: UIImageView?) {
        guard initialMediaIndex < mediaObjects.count && initialMediaIndex >= 0 else {
            return
        }
        let mediaObject = mediaObjects[initialMediaIndex]
        self.galleryMediaObjects = mediaObjects
        let galleryViewController = self.galleryViewController(for: mediaObject, post: post)
        self.presentGalleryViewController(galleryViewController, sourceView: sourceView)
    }
    
    func galleryViewController(for mediaObject: MediaObject, post: Post?) -> AWKGalleryViewController {
        let galleryViewController = AWKGalleryViewController()
        galleryViewController.dataSource = self
        galleryViewController.delegate = self
        galleryViewController.displaysNavigationItemCount = (self.galleryMediaObjects?.count ?? 0) > 1
        galleryViewController.currentItem = mediaObject.galleryItem
        galleryViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_arrow_back"), style: UIBarButtonItemStyle.plain, target: galleryViewController, action: #selector(AWKGalleryViewController.dismissGallery(_:)))
        
        galleryViewController.bottomView = self.bottomView(for: galleryViewController, post: post)
        
        return galleryViewController
    }
    
    func bottomView(for gallery: AWKGalleryViewController, post: Post?) -> UIView? {
        return nil
    }
    
}
