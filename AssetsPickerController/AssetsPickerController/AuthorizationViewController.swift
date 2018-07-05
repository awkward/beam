//
//  AuthorizationViewController.swift
//  AssetsPickerControllerExample
//
//  Created by Rens Verhoeven on 06-04-16.
//  Copyright © 2016 Rens Verhoeven. All rights reserved.
//

import UIKit
import Photos

class AuthorizationViewController: UIViewController, ColorPaletteSupport, AssetsPickerViewController {
    
    var emptyView: UIView?
    weak var assetsPickerController: AssetsPickerController? {
        didSet {
            self.startColorPaletteSupport()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(AuthorizationViewController.cancel(_:)))
        
        self.updateContents()
    }
    
    internal func updateContents() {
        self.emptyView?.removeFromSuperview()
        self.emptyView = nil
        if let view = self.assetsPickerController?.delegate?.assetsPickerController(self.assetsPickerController!, viewForAuthorizationStatus: PHPhotoLibrary.authorizationStatus()) {
            self.emptyView = view
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layoutMargins = UIEdgeInsets(top: self.topLayoutGuide.length + 20, left: 20, bottom: self.bottomLayoutGuide.length + 20, right: 20)
            self.view.addSubview(view)
            self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .leading, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0))
            
        }
        self.view.setNeedsLayout()
    }
    
    @objc fileprivate func cancel(_ sender: AnyObject) {
        self.cancelImagePicking()
    }
    
    deinit {
        self.stopColorPaletteSupport()
    }

    func colorPaletteDidChange() {
        self.view.backgroundColor = self.colorPalette.backgroundColor
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.emptyView?.layoutMargins = UIEdgeInsets(top: self.topLayoutGuide.length + 20, left: 20, bottom: self.bottomLayoutGuide.length + 20, right: 20)
    }

}
