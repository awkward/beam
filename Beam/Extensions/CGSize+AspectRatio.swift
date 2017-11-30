//
//  CGSize+AspectRatio.swift
//  Beam
//
//  Created by Rens Verhoeven on 31/01/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

extension CGSize {
    
    /// Returns aspect ratio as the smallest value. 1 represents 1:1 (square).
    var aspectRatio: CGFloat {
        return min(self.width / self.height, self.height / self.width)
    }

}
