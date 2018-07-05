//
//  EditCommentActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 01-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

final class EditCommentActivity: CustomObjectActivity<Comment> {

    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.edit-comment")
    }
    
    override var activityTitle: String? {
        return AWKLocalizedString("edit-comment-activity-title")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "edit_comment_activity_icon")
    }
    
    override var activityViewController: UIViewController? {
        let storyBoard = UIStoryboard(name: "Comments", bundle: nil)
        let navigationController = storyBoard.instantiateViewController(withIdentifier: "compose") as! CommentsNavigationController
        navigationController.useInteractiveDismissal = false
        let composeViewController = navigationController.topViewController as! CommentComposeViewController
        composeViewController.comment = self.object
        composeViewController.editCommentActivity = self
        return navigationController
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard AppDelegate.shared.authenticationController.isAuthenticated, let username = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username, let comment = self.firstObject(in: activityItems) else {
            return false
        }
        return comment.author == username && !comment.hasBeenDeleted
    }
    
}
