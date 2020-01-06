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
    var colorPaletteChangeObservation: NSObjectProtocol? { get set }
    
    func startColorPaletteSupport()
    func stopColorPaletteSupport()
    
    func colorPaletteDidChange()
    
}

extension ColorPaletteSupport {
    
    var colorPalette: AssetsPickerColorPalette {
        return self.assetsPickerController?.colorPalette ?? AssetsPickerColorPalette()
    }

    func startColorPaletteSupport() {
        self.colorPaletteChangeObservation = NotificationCenter.default.addObserver(forName: AssetsPickerController.colorPaletteDidChangeNotification, object: nil, queue: nil) { notification in
            self.colorPaletteDidChange()
        }
        self.colorPaletteDidChange()
    }
    
    func stopColorPaletteSupport() {
        if let observer = self.colorPaletteChangeObservation {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func colorPaletteDidChangeNotification(_ notification: Notification) {
        self.colorPaletteDidChange()
    }
}
