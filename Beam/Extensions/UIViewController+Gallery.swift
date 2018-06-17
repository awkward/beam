//
//  UIViewController+Gallery.swift
//  Beam
//
//  Created by Rens Verhoeven on 23-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import AWKGallery

class GalleryWindowRootViewController: BeamViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.view.isOpaque = false
        self.view.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.view.isOpaque = false
        self.view.backgroundColor = UIColor.clear
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.view.isOpaque = false
        self.view.backgroundColor = UIColor.clear
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return DisplayModeValue(UIStatusBarStyle.default, darkValue: UIStatusBarStyle.lightContent)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
    }
    
}

extension UIViewController {

    fileprivate var galleryWindow: UIWindow? {
        get {
            return AppDelegate.shared.galleryWindow
        }
        set {
            AppDelegate.shared.galleryWindow = newValue
        }
    }
    
    func presentGalleryViewController(_ galleryViewController: AWKGalleryViewController, sourceView: UIView?, completionHandler: (() -> Void)? = nil) {
        if self.supportedInterfaceOrientations == .all || self.supportedInterfaceOrientations == .allButUpsideDown {
            self.present(galleryViewController, animated: true, completion: {
                sourceView?.isHidden = true
                completionHandler?()
            })
            return
        }
        if self.view.window == self.galleryWindow {
            self.present(galleryViewController, animated: true, completion: { () -> Void in
                sourceView?.isHidden = true
                completionHandler?()
            })
            return
        }
        if self.galleryWindow == nil {
            self.galleryWindow = UIWindow(frame: UIScreen.main.bounds)
            self.galleryWindow!.windowLevel = UIWindowLevelNormal
            self.galleryWindow!.backgroundColor = UIColor.clear
            self.galleryWindow!.tintColor = self.view.window?.tintColor
            
            let viewController = GalleryWindowRootViewController()
            self.galleryWindow?.rootViewController = viewController
        }
        self.galleryWindow!.makeKeyAndVisible()
        self.galleryWindow!.rootViewController!.present(galleryViewController, animated: true, completion: { () -> Void in
            sourceView?.isHidden = true
            completionHandler?()
        })
    }
    
    func dismissGalleryViewController(_ galleryViewController: AWKGalleryViewController, sourceView: UIView?, completionHandler: (() -> Void)? = nil) {
        sourceView?.isHidden = true
        if self.view.window == self.galleryWindow {
            galleryViewController.dismiss(animated: true) { () -> Void in
                sourceView?.isHidden = false
                completionHandler?()
            }
            return
        }
        galleryViewController.dismiss(animated: true) { () -> Void in
            sourceView?.isHidden = false
            self.galleryWindow?.resignKey()
            self.galleryWindow = nil
            // The following line should actually be there, but works without. The line will cause a flickering of the animating gallery view:
//            self.view.window?.makeKeyAndVisible()
            self.view.window?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            completionHandler?()
        }
    }
    
}
