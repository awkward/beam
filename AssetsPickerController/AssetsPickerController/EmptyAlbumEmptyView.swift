//
//  EmptyAlbumEmptyView.swift
//  AssetsPickerControllerExample
//
//  Created by Rens Verhoeven on 14-04-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit

class EmptyAlbumEmptyView: UIView, ColorPaletteSupport {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    weak var assetsPickerController: AssetsPickerController? {
        didSet {
            self.startColorPaletteSupport()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.reloadContents()
    }
    
    deinit {
        self.stopColorPaletteSupport()
    }
    
    func reloadContents() {
        self.titleLabel.text = NSLocalizedString("no-images-title", tableName: nil, bundle: Bundle(for: AuthorizationViewController.self), value: "No images", comment: "The title shown when the album the user has selected is empty")
        self.descriptionLabel.text = NSLocalizedString("no-images-message", tableName: nil, bundle: Bundle(for: AuthorizationViewController.self), value: "This album does not contain any images", comment: "The message shown when the user selected album is empty")
    }
    
    func colorPaletteDidChange() {
        self.backgroundColor = self.colorPalette.backgroundColor
        self.titleLabel.textColor = self.colorPalette.titleColor
        self.descriptionLabel.textColor = self.colorPalette.titleColor
    }
    
}
