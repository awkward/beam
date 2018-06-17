//
//  AuthenticationController+NSFW.swift
//  Beam
//
//  Created by Rens Verhoeven on 08/02/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import Snoo

extension AuthenticationController {
    
    var userCanViewNSFWContent: Bool {
        if !AppDelegate.shared.authenticationController.isAuthenticated {
            return false
        }
        if AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.isOver18.boolValue == false {
            return false
        }
        return true
    }
    
}
