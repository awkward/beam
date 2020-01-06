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
        return self.stringByTrimmingTrailingCharactersInSet(.whitespacesAndNewlines)
    }
    
    func stringByTrimmingTrailingCharactersInSet(_ characterSet: CharacterSet) -> String {
        if let range = rangeOfCharacter(from: characterSet, options: [.anchored, .backwards]) {
            return String(self[..<range.lowerBound]).stringByTrimmingTrailingCharactersInSet(characterSet)
        }
        return self
    }
    
}
