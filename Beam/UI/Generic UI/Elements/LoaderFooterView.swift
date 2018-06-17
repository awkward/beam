//
//  LoaderFooterView.swift
//  beam
//
//  Created by Rens Verhoeven on 29-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class LoaderFooterView: BeamView {

    @IBOutlet fileprivate var activityIndicatorView: UIActivityIndicatorView!
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        if self.displayMode == .dark {
            self.activityIndicatorView?.color = UIColor.white
        } else {
            self.activityIndicatorView?.color = UIColor.lightGray
        }
        self.backgroundColor = UIColor.clear
    }
    
    // MARK: Animation
    
    func startAnimating() {
        self.activityIndicatorView.startAnimating()
    }
    
    func stopAnimating() {
        self.activityIndicatorView.stopAnimating()
    }
    
}
