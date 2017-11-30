//
//  MetadataValueTransformer.swift
//  Snoo
//
//  Created by Robin Speijer on 16-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import UIKit

@objc(MetadataValueTransformer)
final class MetadataValueTransformer: ValueTransformer {
   
    override open class func transformedValueClass() -> Swift.AnyClass {
        return Data.self as! AnyClass
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let value = value as? NSDictionary {
            var json: Data?
            do {
                json = try JSONSerialization.data(withJSONObject: value, options: [])
            } catch let error as NSError {
                NSLog("Could not create json for transforming metadata in value transformer: %@", error)
            }
            return json
        }
        return nil
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let json = value as? Data {
            var object: NSDictionary?
            do {
                object = try JSONSerialization.jsonObject(with: json, options: [] ) as? NSDictionary
            } catch let error as NSError {
                NSLog("Could not parse json for reverse transforming metadata in value transformer: %@", error)
            }
            if object?.isMember(of: NSDictionary.self) == true {
                print("Found an NSDictionary!")
            }
            return object
        }
        return nil
    }
    
}
