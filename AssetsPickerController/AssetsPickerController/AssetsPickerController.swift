//
//  AWKImagePickerController.swift
//  AWKImagePickerController
//
//  Created by Rens Verhoeven on 27-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

public enum AssetsPickerControllerAlbumType {
    case allPhotos
}

public class AssetsPickerController: NSObject {
    
    static internal let ColorPaletteDidChangeNotification = "ColorPaletteDidChange"
    
    // Configurable properties
    weak open var delegate: AssetsPickerControllerDelegate?
    
    public var mediaTypes = [PHAssetMediaType.image]
    
    public var mediaSubtypes: [PHAssetMediaSubtype]?
    
    public var showCameraOption = true
    
    public var multipleSelection = true
    
    public var maxNumberOfSelections = 0
    
    public var hideRecentlyDeletedSmartAlbum = true
    
    public var hideHiddenSmartAlbum = true
    
    public var hideEmptyAlbums = true
    
    public var defaultAlbum: AssetsPickerControllerAlbumType? = AssetsPickerControllerAlbumType.allPhotos
    
    internal var fetchOptions: PHFetchOptions! {
        get {
            if self.cachedFetchOptions == nil {
                self.createFetchOptions()
            }
            return self.cachedFetchOptions!
        }
        set {
            self.cachedFetchOptions = newValue
        }
    }
    
    internal var cachedFetchOptions: PHFetchOptions!
    
    func createFetchOptions() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
        
        var predicates = [NSPredicate]()
        
        var mediaTypePredicates = [NSPredicate]()
        for mediaType in self.mediaTypes {
            mediaTypePredicates.append(NSPredicate(format: "mediaType == %ld", mediaType.rawValue))
        }
        predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: mediaTypePredicates))
        
        if let mediaSubtypes = self.mediaSubtypes {
            var mediaSubtypePredicates = [NSPredicate]()
            for mediaSubtype in mediaSubtypes {
                mediaSubtypePredicates.append(NSPredicate(format: "mediaSubtype == %d", mediaSubtype.rawValue))
            }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: mediaSubtypePredicates))
        }
        
        fetchOptions.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        self.cachedFetchOptions = fetchOptions
    }
    
    open var colorPalette = AssetsPickerColorPalette() {
        didSet {
            if self.colorPalette != oldValue {
                NotificationCenter.default.post(name: Notification.Name(rawValue: AssetsPickerController.ColorPaletteDidChangeNotification), object: self.colorPalette)
            }
        }
    }
    
    open func createNavigationController() -> UINavigationController {
        let navigationController = AssetsPickerNavigationController()
        navigationController.pickerController = self
        return navigationController
    }
    
    open func createNavigationController(_ navigationBarClass: AnyClass?, toolbarClass: AnyClass?) -> UINavigationController {
        let navigationController = AssetsPickerNavigationController(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        navigationController.pickerController = self
        return navigationController
    }
    
    open func createAlbumsViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Interface", bundle: Bundle(for: AssetsPickerController.self))
        let albumsViewController = storyboard.instantiateViewController(withIdentifier: "albums-view") as! AlbumsViewController
        albumsViewController.assetsPickerController = self
        return albumsViewController
    }

}
