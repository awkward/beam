//
//  Album
//  AWKImagePickerControllerExample
//
//  Created by Rens Verhoeven on 29-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

internal class Album: NSObject {
    
    internal static let allPhotosAlbum: Album = {
        return Album(allPhotos: true)
    }()
    
    internal var isAllPhotosAlbum: Bool {
        return self.collection == nil
    }
    
    internal let collection: PHAssetCollection?
    
    internal var title: String {
        if let collection = self.collection {
            return collection.localizedTitle ?? NSLocalizedString("unknown-album-titl", tableName: nil, bundle: Bundle(for: Album.self), value: "Unknowm Album", comment: "Shown as album name if the album name is not available")
        } else {
            return NSLocalizedString("all-photos-title", tableName: nil, bundle: Bundle(for: AssetsPickerController.self), value: "All Photos", comment: "The title for the all photos album")
        }
    }
    
    internal init(collection: PHAssetCollection) {
        self.collection = collection
    }
    
    fileprivate init(allPhotos: Bool) {
        self.collection = nil
    }
    
    fileprivate var previewAsset: PHAsset?
    
    internal func loadPreviewImage(_ targetSize: CGSize, fetchOptions: PHFetchOptions?, completionHandler: @escaping ((_ image: UIImage?) -> Void)) {
        DispatchQueue.global(qos: .default).async {
            var asset: PHAsset?
            if let previewAsset = self.previewAsset {
                asset = previewAsset
            } else {
                let imageFetchOptions: PHFetchOptions!
                if let fetchOptions = fetchOptions {
                    imageFetchOptions = fetchOptions.copy() as! PHFetchOptions
                } else {
                    imageFetchOptions = PHFetchOptions()
                }
                if #available(iOS 9.0, *) {
                    imageFetchOptions.fetchLimit = 1
                } else {
                    // Fallback on earlier versions
                }
                
                var result: PHFetchResult<PHAsset>!
                if let collection = self.collection {
                    result = PHAsset.fetchAssets(in: collection, options: imageFetchOptions)
                } else {
                    result = PHAsset.fetchAssets(with: imageFetchOptions)
                }
                if let resultAsset = result.firstObject {
                    self.previewAsset = resultAsset
                    asset = resultAsset
                }
            }
            
            if let asset = asset {
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = false
                requestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
                PHImageManager.default().requestImage(for: asset, targetSize: targetSize.sizeWithScale(UIScreen.main.scale), contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
                    DispatchQueue.main.async {
                        completionHandler(image)
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
            }
        }

    }
    
    fileprivate var actualNumberOfItems: Int?
    
    func fetchNumberOfItems(_ fetchOptions: PHFetchOptions) -> Int {
        if let numberOfItems = self.actualNumberOfItems {
            return numberOfItems
        } else {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
            var result: PHFetchResult<PHAsset>!
            if let collection = self.collection {
                result = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            } else {
                result = PHAsset.fetchAssets(with: fetchOptions)
            }
            self.actualNumberOfItems = result.count
            return result.count
        }

    }
}
