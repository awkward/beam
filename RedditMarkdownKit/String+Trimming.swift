//
//  String+Trimming.swift
//  beam
//
//  Created by Rens Verhoeven on 26-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

extension NSString {
    
    func stringByTrimmingTrailingWhitespacesAndNewLines() -> NSString {
        return self.stringByTrimmingTrailingCharactersInSet(CharacterSet.whitespacesAndNewlines)
    }
    
    func stringByTrimmingTrailingCharactersInSet(_ characterSet: CharacterSet) -> NSString {
        let string = self as NSString
        var length: Int = string.length
        
        if length == 0 {
            return self
        }
        
        while length > 0 {
            if let character = UnicodeScalar(string.character(at: length - 1)), !characterSet.contains(character) {
                break
            }
            
            length -= 1
        }
        
        if length == string.length {
            return self
        }
        return self.substring(to: length) as NSString
    }
    
    func stringByTrimmingLeadingCharactersInSet(_ characterSet: CharacterSet) -> NSString {
        let string = self as NSString
        
        var location: Int = 0
        let length: Int = string.length
        
        for _ in 0..<length {
            if let character = UnicodeScalar(string.character(at: location)) {
                if !characterSet.contains(character) {
                    break
                }
            }
            location += 1
        }
        
        return self.substring(from: location) as NSString
    }
    
}
