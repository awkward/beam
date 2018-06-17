//
//  EditPostActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 29-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

final class EditPostActivity: CustomObjectActivity<Post> {
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.edit-post")
    }
    
    override var activityTitle: String? {
        return AWKLocalizedString("edit-post-activity-title")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "edit_post_activity_icon")
    }
    
    override var activityViewController: UIViewController? {
        let identifier = "create-text-post"
        let storyBoard = UIStoryboard(name: "CreatePost", bundle: nil)
        guard let navigationController = storyBoard.instantiateViewController(withIdentifier: identifier) as? UINavigationController, let createPostViewController = navigationController.topViewController as? CreatePostViewController else {
            return nil

        }
        createPostViewController.post = self.object
        return navigationController
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard AppDelegate.shared.authenticationController.isAuthenticated, let post = self.firstObject(in: activityItems), let username = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username else {
            return false
        }
        return post.author == username && post.isSelfText == true && post.locked == false && post.archived == false && post.objectName != nil
    }

}
