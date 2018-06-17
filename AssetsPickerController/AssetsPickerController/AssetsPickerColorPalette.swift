//
//  AssetsPickerColorPalette.swift
//  AssetsPickerControllerExample
//
//  Created by Rens Verhoeven on 06-04-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit

open class AssetsPickerColorPalette: NSObject {
    
    open var statusBarStyle = UIStatusBarStyle.default
    
    open var tintColor: UIColor?
    open var barTintColor: UIColor?
    
    open var backgroundColor = UIColor.white
    open var albumCellBackgroundColor = UIColor.white
    open var albumCellSelectedBackgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.00)
    open var assetCellBackgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0)
    open var albumImageBackgroundColor = UIColor(red: 226 / 255, green: 225 / 255, blue: 230 / 255, alpha: 1)

    open var titleColor = UIColor.black
    open var albumTitleColor = UIColor.black
    open var albumCountColor = UIColor.black
    
    open var albumLinesColor = UIColor(red: 226 / 255, green: 225 / 255, blue: 230 / 255, alpha: 1)
    
    open var cameraIconColor = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.00)
    
    internal var titleTextAttributes: [NSAttributedStringKey: Any] {
        return [NSAttributedStringKey.foregroundColor: self.titleColor]
    }
}

func == (lhs: AssetsPickerColorPalette, rhs: AssetsPickerColorPalette) -> Bool {
    if lhs.tintColor == rhs.tintColor &&
        lhs.barTintColor == rhs.barTintColor &&
        lhs.backgroundColor == rhs.backgroundColor &&
        lhs.albumCellBackgroundColor == rhs.albumCellBackgroundColor &&
        lhs.albumCellSelectedBackgroundColor == rhs.albumCellSelectedBackgroundColor &&
        lhs.assetCellBackgroundColor == rhs.assetCellBackgroundColor &&
        lhs.albumImageBackgroundColor == rhs.albumImageBackgroundColor &&
        lhs.titleColor == rhs.titleColor &&
        lhs.albumTitleColor == rhs.albumTitleColor &&
        lhs.albumCountColor == rhs.albumCountColor &&
        lhs.albumLinesColor == rhs.albumLinesColor &&
        lhs.cameraIconColor == rhs.cameraIconColor {
        return true
    }
    return false
}
