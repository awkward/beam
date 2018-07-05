//
//  CGSize+Scale.swift
//  AssetsPickerControllerExample
//
//  Created by Rens Verhoeven on 04-04-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit

extension CGSize {

    func sizeWithScale(_ scale: CGFloat) -> CGSize {
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
}
