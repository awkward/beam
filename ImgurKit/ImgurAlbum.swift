//
//  ImgurAlbum.swift
//  Beam
//
//  Created by Rens Verhoeven on 01-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

open class ImgurAlbum: ImgurObject {
    
    override open var URL: Foundation.URL {
        return Foundation.URL(string: "https://imgur.com/a/\(self.identifier)")!
    }
    
    open var uploadDate: Date?
    open var images: [ImgurImage]?
    
    public override init(dictionary: NSDictionary) {
        if let images = dictionary["images"] as? [NSDictionary] {
            var imgurImages = [ImgurImage]()
            for imageInfo in images {
                imgurImages.append(ImgurImage(dictionary: imageInfo))
            }
            self.images = imgurImages
        }
        if let UTCTime = dictionary["datetime"] as? Double {
            self.uploadDate = Date(timeIntervalSince1970: UTCTime)
        }
        
        NSLog("Album dictionary \(dictionary)")
        
        super.init(dictionary: dictionary)
    }

    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.images, forKey: "images")
        aCoder.encode(self.uploadDate, forKey: "datetime")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.images = aDecoder.decodeObject(forKey: "images") as? [ImgurImage]
        self.uploadDate = aDecoder.decodeObject(forKey: "datetime") as? Date
        super.init(coder: aDecoder)
    }
}
