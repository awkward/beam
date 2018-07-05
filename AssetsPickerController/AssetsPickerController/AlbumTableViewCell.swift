//
//  AlbumTableViewCell.swift
//  AWKImagePickerControllerExample
//
//  Created by Rens Verhoeven on 27-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

class AlbumTableViewCell: UITableViewCell, ColorPaletteSupport {

    weak var assetsPickerController: AssetsPickerController? {
        didSet {
            self.startColorPaletteSupport()
        }
    }
    
    fileprivate static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    class var reuseIdentifier: String {
        return "album-cell"
    }
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var albumView: AlbumImageView!
    
    var album: Album? {
        didSet {
            self.albumChanged = self.album != oldValue
        }
    }
    
    var albumChanged = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    deinit {
        self.stopColorPaletteSupport()
    }
    
    func reloadContents(withFetchOptions fetchOptions: PHFetchOptions) {
        if self.albumChanged {
            self.albumChanged = false
            
            self.titleLabel.text = self.album?.title
            
            if let count = self.album?.fetchNumberOfItems(fetchOptions), count != NSNotFound {
                self.countLabel.text = AlbumTableViewCell.numberFormatter.string(from: NSNumber(value: count))
            } else {
                self.countLabel.text = "0"
            }
            
            self.albumView.imageView.contentMode = UIViewContentMode.center
            self.albumView.image = AssetsPickerControllerStyleKit.imageOfAlbumThumbnailPlaceholder
            self.album?.loadPreviewImage(self.albumView.preferredImageSize, fetchOptions: fetchOptions, completionHandler: { (image) in
                if let image = image {
                    self.albumView.imageView.contentMode = UIViewContentMode.scaleAspectFill
                    self.albumView.image = image
                }
                
            })
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.colorPaletteDidChange()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.colorPaletteDidChange()
    }
    
    func colorPaletteDidChange() {
        let backgroundColor = self.isSelected || self.isHighlighted ? self.colorPalette.albumCellSelectedBackgroundColor : self.colorPalette.albumCellBackgroundColor
        self.contentView.backgroundColor = backgroundColor
        self.backgroundColor = backgroundColor
        
        self.albumView.backgroundColor = backgroundColor
        self.albumView.linesColor = self.colorPalette.albumLinesColor
        self.albumView.placeholderColor = self.colorPalette.albumImageBackgroundColor
        self.albumView.tintColor = self.colorPalette.titleColor.withAlphaComponent(0.3)
        
        self.titleLabel.textColor = self.colorPalette.albumTitleColor
        self.countLabel.textColor = self.colorPalette.albumCountColor
    }
    
}
