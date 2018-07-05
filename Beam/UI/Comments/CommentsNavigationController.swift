//
//  CommentsNavigationController.swift
//  beam
//
//  Created by Rens Verhoeven on 29-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

class CommentsNavigationController: BeamNavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usesRoundedCorners = true
        self.useInteractiveDismissal = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.topViewController?.preferredStatusBarStyle ?? .default
    }
    
}
