//
//  UIAlertController+Unauthenticated.swift
//  Beam
//
//  Created by Rens Verhoeven on 26-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum UnauthenticatedAlertType: String {
    case General = "general"
    case VoteComment = "comment-vote"
    case VotePost = "post-vote"
    case Comment = "comment"
    case CreateMultireddit = "create-multireddit"
    case Subscribe = "subscribe"
    case CreatePost = "create-post"
    case ComposeMessage = "compose-message"
}

extension UIAlertController {
    
    class func unauthenticatedAlertController(_ type: UnauthenticatedAlertType) -> UIAlertController {
        let key = type.rawValue
        let title = AWKLocalizedString("\(key)-login-required")
        let message = AWKLocalizedString("\(key)-login-required-message")
        let alertController = BeamAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addCancelAction()
        
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("login"), style: .default, handler: { (_) -> Void in
            AppDelegate.shared.presentAuthenticationViewController()
        }))
        
        return alertController
    }
}
