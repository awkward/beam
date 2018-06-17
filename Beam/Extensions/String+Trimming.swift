//
//  String+Trimming.swift
//  beam
//
//  Created by Rens Verhoeven on 01-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

extension String {
    
    func stringByTrimmingTrailingWhitespacesAndNewLines() -> String {
        return self.stringByTrimmingTrailingCharactersInSet(CharacterSet.whitespacesAndNewlines)
    }
    
    func stringByTrimmingTrailingCharactersInSet(_ characterSet: CharacterSet) -> String {
        var length: Int = self.utf16.count
        
        while length > 0 {
            let charIndex = self.utf16.index(self.utf16.startIndex, offsetBy: length - 1)
            if !characterSet.contains(UnicodeScalar(self.utf16[charIndex])!) {
                break
            }
            length -= 1
        }
        
        return self.substring(with: self.startIndex..<self.characters.index(self.startIndex, offsetBy: length - 1))
    }
    
}
