//
//  ImgurGalleryToolbar.swift
//  Beam
//
//  Created by Rens Verhoeven on 28-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import ImgurKit

protocol ImgurGalleryToolbarDelegate: class {

    func toolbar(_ toolbar: ImgurGalleryToolbar, didTapDeleteOnImgurObject object: ImgurObject)
}

class ImgurGalleryToolbar: BeamView {

    @IBOutlet var linkLabel: UILabel!
    @IBOutlet var deleteButton: UIButton!
    
    weak var delegate: ImgurGalleryToolbarDelegate?
    
    var imgurObject: ImgurObject? {
        didSet {
            self.linkLabel.text = self.imgurObject?.URL.absoluteString
            self.deleteButton.isHidden = self.imgurObject == nil
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.backgroundColor = UIColor.clear
        self.deleteButton.tintColor = UIColor.white
        self.linkLabel.textColor = UIColor.white
    }
    
    @IBAction func deleteTapped(_ sender: UIButton) {
        guard let imgurObject = self.imgurObject else {
            return
        }
        self.delegate?.toolbar(self, didTapDeleteOnImgurObject: imgurObject)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let lineWidth = 1.0 / UIScreen.main.scale
        context.setLineWidth(lineWidth)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        
        let y = 0 * lineWidth
        context.move(to: CGPoint(x: self.layoutMargins.left, y: y))
        context.addLine(to: CGPoint(x: self.bounds.width - self.layoutMargins.left, y: y))
        context.strokePath()
    }
    
}

extension ImgurGalleryToolbar: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .bottom
    }
    
}
