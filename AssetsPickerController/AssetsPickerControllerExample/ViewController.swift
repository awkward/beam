//
//  ViewController.swift
//  AWKImagePickerController
//
//  Created by Rens Verhoeven on 27-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos
import AssetsPickerController

class ViewController: UIViewController {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var assetsPickerController: AssetsPickerController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showImagePickerTapped(sender: AnyObject) {
        let assetsPickerController = AssetsPickerController()
        assetsPickerController.delegate = self
        assetsPickerController.mediaTypes = [PHAssetMediaType.Image]
        self.presentViewController(assetsPickerController.createNavigationController(), animated: true, completion: nil)
    }
    
    @IBAction func showEmbeddedImagePicker(sender: AnyObject) {
        self.assetsPickerController = AssetsPickerController()
        self.assetsPickerController!.delegate = self
        self.assetsPickerController!.mediaTypes = [PHAssetMediaType.Image]
        
        let navigationController = UINavigationController(rootViewController: self.assetsPickerController!.createAlbumsViewController())
        navigationController.navigationBar.barTintColor = UIColor.blueColor()
        
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    var assets: [PHAsset]? {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assets?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("image-cell", forIndexPath: indexPath) as! ImageCollectionViewCell
        cell.asset = self.assets?[indexPath.item]
        return cell
    }
    
}

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
}

extension ViewController: AssetsPickerControllerDelegate {
    
    func assetsPickerController(assetsPickerController: AssetsPickerController, navigationController: UINavigationController, didSelectAssets assets: [PHAsset]) {
        NSLog("Image picture did finish picking images \(assets)")
        navigationController.dismissViewControllerAnimated(true, completion: nil)
        self.assets = assets
    }
    
}
