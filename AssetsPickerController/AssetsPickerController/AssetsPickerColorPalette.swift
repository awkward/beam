//
//  AssetsPickerColorPalette.swift
//  AssetsPickerControllerExample
//
//  Created by Rens Verhoeven on 06-04-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit

open class AssetsPickerColorPalette: NSObject {
    
    public var statusBarStyle = UIStatusBarStyle.default
    
    public var tintColor: UIColor?
    public var barTintColor: UIColor?
    
    public var backgroundColor = UIColor.white
    public var albumCellBackgroundColor = UIColor.white
    public var albumCellSelectedBackgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.00)
    public var assetCellBackgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0)
    public var albumImageBackgroundColor = UIColor(red: 226 / 255, green: 225 / 255, blue: 230 / 255, alpha: 1)

    public var titleColor = UIColor.black
    public var albumTitleColor = UIColor.black
    public var albumCountColor = UIColor.black
    
    public var albumLinesColor = UIColor(red: 226 / 255, green: 225 / 255, blue: 230 / 255, alpha: 1)
    
    public var cameraIconColor = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.00)
    
    internal var titleTextAttributes: [NSAttributedString.Key: Any] {
        return [NSAttributedString.Key.foregroundColor: self.titleColor]
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
