//
//  AssetsPickerNavigationController.swift
//  AssetsPickerControllerExample
//
//  Created by Rens Verhoeven on 25-05-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

internal class AssetsPickerNavigationController: UINavigationController, ColorPaletteSupport {
    
    var pickerController: AssetsPickerController!
    
    weak var assetsPickerController: AssetsPickerController? {
        get {
            return self.pickerController
        }
        set {
            //Ignore the setter
        }
    }

    internal override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.colorPalette.statusBarStyle
    }
    
    func colorPaletteDidChange() {
        self.setNeedsStatusBarAppearanceUpdate()
        self.view.tintColor = self.colorPalette.tintColor
        self.navigationBar.titleTextAttributes = self.colorPalette.titleTextAttributes
    }
    
    override internal func viewDidLoad() {
        super.viewDidLoad()

        self.startColorPaletteSupport()
        
        self.updateRootViewControllers()
        
        self.colorPaletteDidChange()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AssetsPickerNavigationController.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        self.stopColorPaletteSupport()
        NotificationCenter.default.removeObserver(self)
    }
    
    internal override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override internal func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.notDetermined {
            PHPhotoLibrary.requestAuthorization({ (status) in
                self.authorizationStatusDidChange(status)
            })
        } else {
            self.authorizationStatusDidChange(PHPhotoLibrary.authorizationStatus())
        }
    }
    
    fileprivate func updateRootViewControllers() {
        let storyboard = UIStoryboard(name: "Interface", bundle: Bundle(for: AssetsPickerController.self))
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
            if let firstViewController = self.viewControllers.first as? AuthorizationViewController {
                firstViewController.updateContents()
            } else {
                let authorizationViewController = AuthorizationViewController()
                authorizationViewController.assetsPickerController = self.assetsPickerController
                self.viewControllers = [authorizationViewController]
            }

        } else {
            let firstViewController = self.viewControllers.first
            if firstViewController == nil || !(firstViewController! is AlbumsViewController) {
                if let albumsViewController = storyboard.instantiateViewController(withIdentifier: "albums-view") as? AlbumsViewController {
                    albumsViewController.assetsPickerController = self.assetsPickerController
                    var viewControllers: [UIViewController] = [albumsViewController]
                    if let gridViewController = storyboard.instantiateViewController(withIdentifier: "assets-grid") as? AssetsGridViewController, self.pickerController.defaultAlbum == AssetsPickerControllerAlbumType.allPhotos {
                        gridViewController.assetsPickerController = self.assetsPickerController
                        gridViewController.album = Album.allPhotosAlbum
                        viewControllers.append(gridViewController)
                    }
                    self.viewControllers = viewControllers
                }
            }
        }
    }
    
    @objc fileprivate func applicationDidBecomeActive(_ notification: Notification) {
        self.updateRootViewControllers()
    }
    
    fileprivate func authorizationStatusDidChange(_ status: PHAuthorizationStatus) {
        self.updateRootViewControllers()
    }

}
