//
//  AlbumView.swift
//  AWKImagePickerControllerExample
//
//  Created by Rens Verhoeven on 29-03-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit

@IBDesignable
class AlbumImageView: UIView {
    
    var linesColor = UIColor.black {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var placeholderColor = UIColor(red: 226 / 255, green: 225 / 255, blue: 230 / 255, alpha: 1) {
        didSet {
            self.imageView.backgroundColor = self.placeholderColor
        }
    }

    var image: UIImage? {
        set {
            self.imageView.image = newValue
        }
        get {
            return self.imageView.image
        }
    }
    
    var preferredImageSize: CGSize {
        return CGSize(width: 70, height: 70)
    }
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isOpaque = true
        imageView.backgroundColor = self.placeholderColor
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    func setupView() {
        self.addSubview(self.imageView)
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        let firstLinePath = UIBezierPath(rect: CGRect(x: 7, y: 0, width: rect.width - (7 * 2), height: 1 / UIScreen.main.scale))
        self.linesColor.withAlphaComponent(0.4).setFill()
        firstLinePath.fill()
        
        let secondLinePath = UIBezierPath(rect: CGRect(x: 4, y: 2, width: rect.width - (4 * 2), height: 1 / UIScreen.main.scale))
        self.linesColor.withAlphaComponent(0.6).setFill()
        secondLinePath.fill()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 70, height: 74)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = CGRect(x: 0, y: 4, width: self.bounds.width, height: self.bounds.height - 4)
    }
    
}
