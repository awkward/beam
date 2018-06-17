//
//  CommentCellContentView.swift
//  Beam
//
//  Created by Rens Verhoeven on 22-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

class CommentCellContentView: BeamView {
    
    var commentIndentationLevel: Int = 0 {
        didSet {
            var layoutMargins = self.layoutMargins
            var leftMargin: CGFloat = 12
            if self.commentIndentationLevel > 0 {
                let step: CGFloat = self.indentationLevelWidth
                leftMargin += step * CGFloat(self.commentIndentationLevel)
            }
            layoutMargins.left = leftMargin
            layoutMargins.right = 12
            self.layoutMargins = layoutMargins
        }
    }
    var showTopSeperator: Bool = true
    var showBottomSeperator: Bool = true
    var maxNumberOfReplyBorders: Int = 7 {
        didSet {
            self.createReplyBorderColors()
        }
    }
    
    fileprivate var replyBorderColors: [UIColor] = [UIColor]()

    fileprivate func createReplyBorderColors() {
        let baseColor = DisplayModeValue(UIColor.beamTableViewSeperatorColor(), darkValue: UIColor.beamDarkTableViewSeperatorColor())
        let minimumAlphaValue: CGFloat = 0.1
        let alphaStepValue: CGFloat = (1.0 - minimumAlphaValue) / CGFloat(self.maxNumberOfReplyBorders)
        
        var alpha: CGFloat = 1.0
        self.replyBorderColors.removeAll()
        for _ in 0...self.maxNumberOfReplyBorders {
            
            self.replyBorderColors.append(baseColor.withAlphaComponent(alpha))
            
            alpha -= alphaStepValue
            
            if alpha < minimumAlphaValue {
                alpha = 1.0
            }
        }
    }
    
    fileprivate let indentationLevelWidth: CGFloat = 8.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    fileprivate func setupView() {
        self.isOpaque = true
        self.clipsToBounds = true
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.createReplyBorderColors()
        
        self.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let borderWidth: CGFloat = self.indentationLevelWidth / 2
        let borderSpacing: CGFloat = self.indentationLevelWidth / 2
        if self.commentIndentationLevel > 0 {
            var xPosition: CGFloat = 0
            for index in 0..<self.self.commentIndentationLevel {
                let color = self.replyBorderColors[index]
                
                let borderRect = CGRect(x: xPosition, y: 0, width: borderWidth, height: self.bounds.height)
                let borderPath = UIBezierPath(rect: borderRect)
                color.setFill()
                borderPath.fill()
                
                xPosition += borderWidth
                xPosition += borderSpacing
            }
        }
        
        let seperatorColor = DisplayModeValue(UIColor.beamTableViewSeperatorColor(), darkValue: UIColor.beamDarkTableViewSeperatorColor())
        let seperatorHeight = 1 / UIScreen.main.scale
        if self.showTopSeperator {
            
            var xPosition: CGFloat = 0
            if self.commentIndentationLevel - 1 > 0 {
                xPosition = (self.indentationLevelWidth * CGFloat(self.commentIndentationLevel - 1))
            }
            
            let rect = CGRect(x: xPosition, y: 0, width: self.bounds.width, height: seperatorHeight)
            let path = UIBezierPath(rect: rect)
            seperatorColor.setFill()
            path.fill()
        }
        
        if self.showBottomSeperator {
            let rect = CGRect(x: 0, y: self.bounds.maxY - seperatorHeight, width: self.bounds.width, height: seperatorHeight)
            let path = UIBezierPath(rect: rect)
            seperatorColor.setFill()
            path.fill()
        }
    }

}
