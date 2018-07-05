//
//  AlbumsViewController.swift
//  AWKImagePickerController
//
//  Created by Rens Verhoeven on 27-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

class AlbumsViewController: UITableViewController, AssetsPickerViewController, ColorPaletteSupport {
    
    weak var assetsPickerController: AssetsPickerController? {
        didSet {
            self.startColorPaletteSupport()
        }
    }

    fileprivate var albums: [Album]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.startLoadingAlbums()
        
        self.title = self.assetsPickerController?.delegate?.assetsPickerController(self.assetsPickerController!, navigationBarTitleForAlbumsView: self.albums?.count) ?? NSLocalizedString("albums-title", tableName: nil, bundle: Bundle(for: AlbumsViewController.self), value: "Albums", comment: "The title at the top of the albums view")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.navigationController is AssetsPickerNavigationController {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(AlbumsViewController.cancel(_:)))
        }
    }

    deinit {
        self.stopColorPaletteSupport()
    }
    
    fileprivate func startLoadingAlbums() {
        var albums = [Album.allPhotosAlbum]
        
        let smartAlbumResults = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        smartAlbumResults.enumerateObjects({ (collection, _, _) in
            
            if self.smartAlbumAllowed(collection) && ((self.assetsPickerController?.hideEmptyAlbums == true && collection.estimatedAssetCount > 0 && collection.estimatedAssetCount != NSNotFound) || self.assetsPickerController?.hideEmptyAlbums == false) {
                    albums.append(Album(collection: collection))
            }
        })
        
        let albumResults = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        albumResults.enumerateObjects({ (collection, _, _) in
            if let collection = collection as? PHAssetCollection, (self.assetsPickerController?.hideEmptyAlbums == true && collection.estimatedAssetCount > 0 && collection.estimatedAssetCount != NSNotFound) || self.assetsPickerController?.hideEmptyAlbums == false {
                    albums.append(Album(collection: collection))
            }
        })
        self.albums = albums
    }
    
    fileprivate func smartAlbumAllowed(_ collection: PHAssetCollection) -> Bool {
        guard collection.assetCollectionType == PHAssetCollectionType.smartAlbum else {
            //Normal albums are all allowed
            return true
        }
        var bannedAlbumNames = [String]()
        if self.assetsPickerController?.hideRecentlyDeletedSmartAlbum == true {
            bannedAlbumNames.append(contentsOf: self.recentlyDeletedAlbumLocalizedNames)
        }
        if self.assetsPickerController?.hideHiddenSmartAlbum == true {
            bannedAlbumNames.append(contentsOf: self.recentlyDeletedAlbumLocalizedNames)
        }
        if let title = collection.localizedTitle?.lowercased(), bannedAlbumNames.contains(title) {
            return false
        }
        
        var bannedAlbumSubtypes = [PHAssetCollectionSubtype.smartAlbumAllHidden]
        if !self.assetsPickerController!.mediaTypes.contains(PHAssetMediaType.video) {
            bannedAlbumSubtypes.append(PHAssetCollectionSubtype.smartAlbumTimelapses)
            bannedAlbumSubtypes.append(PHAssetCollectionSubtype.smartAlbumVideos)
            bannedAlbumSubtypes.append(PHAssetCollectionSubtype.smartAlbumSlomoVideos)
        }
        
        if !self.assetsPickerController!.mediaTypes.contains(PHAssetMediaType.image) {
            bannedAlbumSubtypes.append(PHAssetCollectionSubtype.smartAlbumBursts)
            bannedAlbumSubtypes.append(PHAssetCollectionSubtype.smartAlbumPanoramas)
            if #available(iOS 9.0, *) {
                bannedAlbumSubtypes.append(PHAssetCollectionSubtype.smartAlbumScreenshots)
            }
        }
        
        return !bannedAlbumSubtypes.contains(collection.assetCollectionSubtype)
    }
    
    fileprivate var recentlyDeletedAlbumLocalizedNames = ["recently deleted", "eliminado", "zuletzt gelöscht", "supprimés récemment", "onlangs verwijderd", "eliminati di recente"]

    fileprivate var hiddenAlbumLocalizedNames = ["hidden", "oculto", "ausgeblendet", "masqués", "verborgen", "nascosti"]
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.albums?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AlbumTableViewCell.reuseIdentifier, for: indexPath) as! AlbumTableViewCell
        cell.assetsPickerController = self.assetsPickerController
        cell.album = self.albums?[(indexPath as NSIndexPath).row]
        cell.reloadContents(withFetchOptions: self.assetsPickerController!.fetchOptions)
        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let cell = sender as? UITableViewCell, let indexPath = self.tableView.indexPath(for: cell), let gridViewController = segue.destination as? AssetsGridViewController {
            gridViewController.assetsPickerController = self.assetsPickerController
            gridViewController.album = self.albums?[(indexPath as NSIndexPath).row]
        }
    }
 
    @objc fileprivate func cancel(_ sender: AnyObject) {
        self.cancelImagePicking()
    }
    
    // MARK: Color palette support
    
    func colorPaletteDidChange() {
        self.view.backgroundColor = self.colorPalette.backgroundColor
    }

}
