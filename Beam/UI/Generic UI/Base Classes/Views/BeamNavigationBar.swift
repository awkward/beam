//
//  BeamNavigationBar.swift
//  Beam
//
//  Created by Rens Verhoeven on 01-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

@available(*, deprecated, message: "Use stock iOS navigation bar.")
class BeamNavigationBar: UINavigationBar, BeamAppearance {
    
    var showProgressView = false {
        didSet {
            self.progressView.isHidden = !self.showProgressView
        }
    }
    
    var showBottomBorder = true {
        didSet {
            self.bottomBorderOverlay.isHidden = !self.showBottomBorder
        }
    }
    
    //Overriding drawRect in UIToolbar, UITabBar or UINavigationBar disables the background blur. That's why I use views that overlay the border
    var bottomBorderOverlay: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var progressView: UIProgressView = {
        let view = UIProgressView()
        view.trackTintColor = UIColor.clear
        view.progress = 0
        view.progressViewStyle = UIProgressView.Style.bar
        view.isHidden = !self.showProgressView
        return view
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    func setupView() {
        self.addSubview(self.progressView)
    }
    
    func appearanceDidChange() {
        self.barTintColor = self.userInterfaceStyle == .dark ? UIColor.beamDarkBackground : UIColor.beamBar
        
        let borderColor = AppearanceValue(light: UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), dark: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
        self.bottomBorderOverlay.backgroundColor = borderColor
        
        self.progressView.progressTintColor = AppearanceValue(light: UIColor.beam, dark: UIColor.beamPurpleLight)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.bottomBorderOverlay.superview == nil {
            self.addSubview(self.bottomBorderOverlay)
        }
        
        let borderHeight: CGFloat = 1.0 / UIScreen.main.scale
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: borderHeight)
        self.layer.shadowOpacity = 0.05
        self.layer.shadowRadius = 1
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        
        self.bottomBorderOverlay.frame = CGRect(x: 0, y: self.bounds.maxY, width: self.bounds.width, height: borderHeight)
        
        let progressViewHeight: CGFloat = self.progressView.intrinsicContentSize.height
        self.progressView.frame = CGRect(x: 0, y: self.bounds.maxY - progressViewHeight - borderHeight, width: self.bounds.width, height: progressViewHeight)
    }
    
    func updateProgress(_ progress: CGFloat, animated: Bool = true) {
        self.progressView.setProgress(Float(progress), animated: animated)
    }

}
