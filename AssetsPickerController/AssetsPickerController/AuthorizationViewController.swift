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
    
    internal var colorPaletteChangeObservation: NSObjectProtocol?
    
    var emptyView: UIView?
    weak var assetsPickerController: AssetsPickerController? {
        didSet {
            self.startColorPaletteSupport()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(AuthorizationViewController.cancel(_:)))
        
        self.updateContents()
    }
    
    internal func updateContents() {
        self.emptyView?.removeFromSuperview()
        self.emptyView = nil
        if let authorizationView = self.assetsPickerController?.delegate?.assetsPickerController(self.assetsPickerController!, viewForAuthorizationStatus: PHPhotoLibrary.authorizationStatus()), let view = self.view {
            self.emptyView = authorizationView
            authorizationView.translatesAutoresizingMaskIntoConstraints = false
            authorizationView.layoutMargins = UIEdgeInsets(top: self.topLayoutGuide.length + 20, left: 20, bottom: self.bottomLayoutGuide.length + 20, right: 20)
            self.view.addSubview(authorizationView)
            self.view.addConstraints([
                NSLayoutConstraint(item: view, attribute: .top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: authorizationView, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: view, attribute: .leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: authorizationView, attribute: .leading, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: view, attribute: .leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: authorizationView, attribute: .leading, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: authorizationView, attribute: .trailing, multiplier: 1.0, constant: 0)
            ])
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
