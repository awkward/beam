//
//  StoreProductPreview.swift
//  beam
//
//  Created by Robin Speijer on 19-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import AWKGallery

struct StoreProductPreview: Equatable {
    
    var index: Int
    var imageName: String
    var movieURLString: String?
    var product: StoreProduct
    
    init(atIndex index: Int, imageName: String, product: StoreProduct) {
        self.index = index
        self.imageName = imageName
        self.product = product
    }
    
    var image: UIImage? {
        return UIImage(named: self.imageName)
    }

}

func ==(lhs: StoreProductPreview, rhs: StoreProductPreview) -> Bool {
    return (lhs.product == rhs.product && lhs.index == rhs.index)
}

class StoreProductPreviewGalleryItem: NSObject, AWKGalleryItem {
    
    let sourceItem: StoreProductPreview
    lazy var image: UIImage? = { self.sourceItem.image }()
    
    init(sourceItem: StoreProductPreview) {
        self.sourceItem = sourceItem
        super.init()
    }
    
    var contentURL: URL? {
        if let movieString = self.sourceItem.movieURLString {
            return URL(string: movieString)
        }
        return nil
    }
    
    var contentType: AWKGalleryItemContentType {
        get {
            return self.sourceItem.movieURLString == nil ? .image : .movie
        }
        set {
            
        }
    }
    
    var placeholderImage: UIImage? {
        return self.image
    }
    
    var contentData: Any? {
        get {
            return self.image
        }
        set {
            
        }
    }
    
}
