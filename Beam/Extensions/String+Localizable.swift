//
//  String+Localizable.swift
//  Beam
//
//  Created by Rens Verhoeven on 08/12/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

extension String {
    
    /// Replaces placeholders in a localizable string
    /// Placeholders should be formatted like this: [KEY]. with an uppercased key name to make sure it clear it's a placeholder
    ///
    /// - Parameter keys: The keys and associated values to be replaced. The keys shouldn't include the square brackets
    /// - Returns: The new string ready for display
    public func replacingLocalizablePlaceholders(for keys: [String: String]) -> String {
        guard keys.count > 0 else {
            return self
        }
        
        var newString = self
        for (key, value) in keys {
            newString = newString.replacingOccurrences(of: "[\(key.uppercased())]", with: value)
        }
        
        return newString
    }

}
