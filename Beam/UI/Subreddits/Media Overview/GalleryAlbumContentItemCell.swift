//
//  GalleryAlbumContentItemCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 29/12/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class GalleryAlbumContentItemCell: PostImageCollectionPartItemCell {

    override func appearanceDidChange() {
        super.appearanceDidChange()
        
        self.progressView.color = UIColor.white
        self.mediaImageView.backgroundColor = UIColor(red: 56 / 255, green: 56 / 255, blue: 56 / 255, alpha: 1.0)
    }

}
