//
//  BeamAlertController.swift
//  Beam
//
//  Created by Rens Verhoeven on 21-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

//Subclass UIAlertController is not recommended if you change the view hierachy, but we don't
class BeamAlertController: UIAlertController {
    
    func addCloseAction(_ handler: ((_ action: UIAlertAction) -> Void)? = nil) {
        self.addAction(UIAlertAction(title: AWKLocalizedString("close-button"), style: UIAlertActionStyle.cancel, handler: handler))
    }
    
    func addCancelAction(_ handler: ((_ action: UIAlertAction) -> Void)? = nil) {
        self.addAction(UIAlertAction(title: AWKLocalizedString("cancel-button"), style: UIAlertActionStyle.cancel, handler: handler))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Setting the tintColor is broken in iOS 9, we have to change the tintColor everytime the view layout changes
        self.view.tintColor = UIColor.beamColor()
    }

}
