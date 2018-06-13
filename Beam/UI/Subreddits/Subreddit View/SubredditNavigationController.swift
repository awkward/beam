//
//  SubredditNavigationController.swift
//  beam
//
//  Created by Rens Verhoeven on 19-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

final class SubredditNavigationController: BeamNavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usesRoundedCorners = UIDevice.current.userInterfaceIdiom == .phone
    }
}
