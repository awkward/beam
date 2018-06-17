//
//  Array+Limit.swift
//  beam
//
//  Created by Robin Speijer on 14-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

extension Array {
    
    func arrayWithLimit(_ limit: Int) -> [Element] {
        let max = limit < count ? limit: count
        return Array(self[0..<max])
    }
    
}
