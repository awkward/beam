//
//  ImgurImage.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

open class ImgurImage: ImgurObject {

    fileprivate var privateImageURL: Foundation.URL?
    open var imageURL: Foundation.URL {
        if let privateImageURL = self.privateImageURL {
            return privateImageURL
        }
        return Foundation.URL(string: "https://imgur.com/\(self.identifier).jpg")!
    }
    
    override open var URL: Foundation.URL {
        return Foundation.URL(string: "https://imgur.com/\(self.identifier)")!
    }
    
    open var animated: Bool
    open var imageSize: CGSize?
    open var uploadDate: Date?
    
    public override init(dictionary: NSDictionary) {
        self.animated = dictionary["animated"] as? Bool ?? false
        self.privateImageURL = Foundation.URL(string: dictionary["link"] as? String ?? "")
        if let width = dictionary["width"] as? CGFloat, let height = dictionary["height"] as? CGFloat {
            self.imageSize = CGSize(width: width, height: height)
        }
        if let UTCTime = dictionary["datetime"] as? Double {
            self.uploadDate = Date(timeIntervalSince1970: UTCTime)
        }
        
        NSLog("Image dictionary \(dictionary)")
        
        super.init(dictionary: dictionary)
    }
    
    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.privateImageURL, forKey: "link")
        aCoder.encode(self.animated, forKey: "animated")
        aCoder.encode(self.uploadDate, forKey: "datetime")
        if let imageSize = self.imageSize {
            aCoder.encode(imageSize, forKey: "image_size")
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.privateImageURL = aDecoder.decodeObject(forKey: "link") as? Foundation.URL
        self.animated = aDecoder.decodeBool(forKey: "animated")
        self.uploadDate = aDecoder.decodeObject(forKey: "datetime") as? Date
        if aDecoder.containsValue(forKey: "image_size") {
            self.imageSize = aDecoder.decodeCGSize(forKey: "image_size")
        }
        super.init(coder: aDecoder)
    }

}
