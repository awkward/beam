//
//  ProductPreviewCollectionViewCell.swift
//  beam
//
//  Created by Robin Speijer on 18-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class ProductPreviewCollectionViewCell: BeamCollectionViewCell {
    
    @IBOutlet fileprivate(set) var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView.accessibilityIgnoresInvertColors = true
    }
    
    var productPreview: StoreProductPreview? {
        didSet {
            if let imageName = productPreview?.imageName {
                self.imageView.image = UIImage(named: imageName)
            } else {
                self.imageView.image = nil
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.imageView.alpha = isHighlighted ? 0.5 : 1
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = self.backgroundColor
        self.selectedBackgroundView?.backgroundColor = self.backgroundColor
        self.imageView.backgroundColor = self.backgroundColor
        self.imageView.clipsToBounds = true
        
    }
    
}
