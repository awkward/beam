//
//  PostMediaCollectionController.swift
//  beam
//
//  Created by Robin Speijer on 07-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

class PostMediaCollectionController: NSObject {
    
    typealias MediaCollectionItem = Snoo.MediaObject
    
    var collection: [MediaCollectionItem]?
    
    var post: Post? {
        didSet {
            self.collection = self.post?.mediaObjects?.array as? [MediaCollectionItem]
        }
    }
    
    var count: Int {
        return self.collection?.count ?? 0
    }
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> MediaCollectionItem? {
        return self.collection?[indexPath.item]
    }
    
    func indexPathForCollectionItem(_ item: MediaCollectionItem) -> IndexPath? {
        if let collection = self.collection {
            for (index, object) in collection.enumerated() {
                if item == object {
                    return IndexPath(item: index, section: 0)
                }
            }
        }
        return nil
    }

}
