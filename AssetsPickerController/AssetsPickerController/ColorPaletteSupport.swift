//
//  ColorPaletteSupport.swift
//  AssetsPickerControllerExample
//
//  Created by Rens Verhoeven on 06-04-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit

internal protocol ColorPaletteSupport: class {

    var assetsPickerController: AssetsPickerController? { get set }
    var colorPalette: AssetsPickerColorPalette { get }
    
    func startColorPaletteSupport()
    func stopColorPaletteSupport()
    
    func colorPaletteDidChange()
    
}

extension ColorPaletteSupport {
    
    var colorPalette: AssetsPickerColorPalette {
        return self.assetsPickerController?.colorPalette ?? AssetsPickerColorPalette()
    }

    func startColorPaletteSupport() {
        NotificationCenter.default.addObserver(self, selector: Selector("colorPaletteDidChangeNotification:"), name: NSNotification.Name(rawValue: AssetsPickerController.ColorPaletteDidChangeNotification), object: nil)
        self.colorPaletteDidChange()
    }
    
    func stopColorPaletteSupport() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: AssetsPickerController.ColorPaletteDidChangeNotification), object: nil)
    }
    
    func colorPaletteDidChangeNotification(_ notification: Notification) {
        self.colorPaletteDidChange()
    }
}
