//
//  NSDictionaryExtensions.swift
//  Snoo
//
//  Created by Rens Verhoeven on 05/07/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//

import Foundation

extension NSDictionary {
    
    /// Allows getting the first value for a set of keyPaths. If the first keyPath doesn't return a value it will check the next key path.
    ///
    /// - Parameter keyPaths: The keyPaths to find the value with.
    /// - Returns: The value, if found.
    public func firstValue(forKeyPaths keyPaths: [String]) -> Any? {
        for keyPath in keyPaths {
            guard let value = value(forKeyPath: keyPath) else {
                continue
            }
            return value
        }
        return nil
    }
    
}
