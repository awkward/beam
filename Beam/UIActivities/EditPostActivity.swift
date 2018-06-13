//
//  EditPostActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 29-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

class EditPostActivity: UIActivity {
    
    fileprivate var post: Post?
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.edit-post")
    }
    
    override var activityTitle : String? {
        return AWKLocalizedString("edit-post-activity-title")
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "edit_post_activity_icon")
    }
    
    override var activityViewController : UIViewController? {
        let identifier = "create-text-post"
        let storyBoard = UIStoryboard(name: "CreatePost", bundle: nil)
        if let navigationController = storyBoard.instantiateViewController(withIdentifier: identifier) as? UINavigationController, let createPostViewController = navigationController.topViewController as? CreatePostViewController {
            createPostViewController.post = self.post
            return navigationController
        }
        return nil
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard AppDelegate.shared.authenticationController.isAuthenticated == true else {
            return false
        }
        if let username = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username {
            for item in activityItems {
                if let post = item as? Post , post.author == username && post.isSelfText == true && post.locked == false && post.archived == false && post.objectName != nil {
                    return true
                }
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if item is Post {
                self.post = item as? Post
            }
        }
    }

}
