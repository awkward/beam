//
//  String+Removal.swift
//  Beam
//
//  Created by Rens Verhoeven on 27-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

extension String {
    
    func stringByRemovingStrings(_ strings: [String]) -> String {
        var newString = self
        for string in strings {
            if let range = newString.range(of: string) {
                newString.replaceSubrange(range, with: "")
            }
        }
        return newString
    }
    
    mutating func removeStrings(_ strings: [String]) {
        for string in strings {
            if let range = self.range(of: string) {
                self.replaceSubrange(range, with: "")
            }
        }
    }

}
