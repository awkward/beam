//
//  NSRange+Offset.swift
//  Beam
//
//  Created by Rens Verhoeven on 19-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

extension NSRange {
    
    func rangeWithLocationoffset(_ locationOffset: Int) -> NSRange {
        var range = self
        range.location += locationOffset
        return range
    }
}
