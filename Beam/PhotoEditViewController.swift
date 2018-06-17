//
//  ImageEditViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 04-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Photos

class ImageEditViewController: UIViewController {
    
    var allImages: [ImageAsset]!
    var currentImage: [ImageAsset]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ImageEditViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.allImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let image = self.allImages[indexPath.row]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("image-cell", forIndexPath: indexPath) as! ImageAssetCollectionViewCell
        cell.imageAsset = image
        cell.reloadContents(self.view.bounds.size, imageManager: PHImageManager.defaultManager())
        return cell
    }
}

extension ImageEditViewController: UICollectionViewDelegateFlowLayout {
    
}
