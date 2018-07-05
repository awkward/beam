//
//  ImgurObject.swift
//  Beam
//
//  Created by Rens Verhoeven on 31-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

open class ImgurObject: NSObject, NSCoding {
    
    open var identifier: String
    open var deleteHash: String?
    open var URL: Foundation.URL {
        return Foundation.URL(string: "https://imgur.com/\(self.identifier)")!
    }
    
    public init(dictionary: NSDictionary) {
        self.identifier = dictionary["id"] as! String
        self.deleteHash = dictionary["deletehash"] as? String
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.identifier, forKey: "id")
        aCoder.encode(self.deleteHash, forKey: "deletehash")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.identifier = aDecoder.decodeObject(forKey: "id") as! String
        self.deleteHash = aDecoder.decodeObject(forKey: "deletehash") as? String
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let imgurObject = object as? ImgurObject else {
            return false
        }
        return imgurObject.identifier == self.identifier && object_getClassName(imgurObject) == object_getClassName(self)
    }

}

func == (lhs: ImgurObject, rhs: ImgurObject) -> Bool {
    return lhs.identifier == rhs.identifier && object_getClassName(rhs) == object_getClassName(lhs)
}
