//
//  MetadataHandling.swift
//  Snoo
//
//  Created by Rens Verhoeven on 14-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

public protocol MetadataHandling: class {

    var metadata: NSDictionary? { get set }
    
    func setMetadataValue(_ value: Any, forKey key: String)
    func removeMetadataValueForKey(_ key: String)
    func metadataValueForKey(_ key: String) -> Any?
}

extension MetadataHandling {
    
    public func setMetadataValue(_ value: Any, forKey key: String) {
        var newValue = value
        if let url = newValue as? URL {
            let urlString: String = url.absoluteString
            newValue = urlString
            NSLog("Warning: NSURL is not supported in metadata, it will be inserted and returned as string")
        }
        var metadata = self.metadata
        if metadata == nil {
            metadata = NSDictionary(object: newValue, forKey: key as NSCopying)
        } else {
            let newMetadata = NSMutableDictionary(dictionary: metadata!)
            newMetadata[key] = newValue
            metadata = NSDictionary(dictionary: newMetadata)
        }
        self.metadata = metadata!
    }
    
    public func removeMetadataValueForKey(_ key: String) {
        if let metadata = self.metadata {
            let newMetadata = NSMutableDictionary(dictionary: metadata)
            newMetadata.removeObject(forKey: key)
            self.metadata = NSDictionary(dictionary: newMetadata)
        }
    }
    
    public func metadataValueForKey(_ key: String) -> Any? {
        if let metadata = self.metadata {
            return metadata[key]
        }
        return nil
    }
    
}
