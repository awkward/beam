//
//  SavePostActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 21-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

class SaveContentActivity<T: Content>: CustomObjectActivity<T> {
    
    internal var shouldSaveContent: Bool {
        return true
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard AppDelegate.shared.authenticationController.isAuthenticated, let content = self.firstObject(in: activityItems) else {
            return false
        }
        return content.isSaved.boolValue == !self.shouldSaveContent && !content.hasBeenDeleted
    }
    
    override func perform() {
        guard AppDelegate.shared.authenticationController.isAuthenticated, let content = self.object else {
            return
        }
        content.isSaved = NSNumber(value: self.shouldSaveContent)
        let operation = content.saveToRedditOperation(self.shouldSaveContent, authenticationController: AppDelegate.shared.authenticationController)
        DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.activityDidFinish(true)
                if error != nil {
                    let isPost = content is Post
                    let title = isPost ? AWKLocalizedString("post-save-error") : AWKLocalizedString("comment-save-error")
                    let message = isPost ? AWKLocalizedString("post-save-error-message") : AWKLocalizedString("comment-save-error-message")
                    let alertController = BeamAlertController(title: title, message: message, preferredStyle: .alert)
                    alertController.addCloseAction()
                    AppDelegate.topViewController()?.present(alertController, animated: true, completion: nil)
                } else {
                    NotificationCenter.default.post(name: .ContentDidChangeSavedState, object: content)
                }
            })
        })
    }
    
}

final class SavePostActivity: SaveContentActivity<Post> {
    
    override internal var shouldSaveContent: Bool {
        return true
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.save-post")
    }
    
    override var activityTitle: String? {
        return AWKLocalizedString("post-save-activity-title")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "save_activity_icon")
    }
    
}

final class UnsavePostActivity: SaveContentActivity<Post> {
    
    override internal var shouldSaveContent: Bool {
        return false
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.unsave-post")
    }
    
    override var activityTitle: String? {
        return AWKLocalizedString("post-unsave-activity-title")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "unsave_activity_icon")
    }
    
}

final class SaveCommentActivity: SaveContentActivity<Comment> {
    
    override internal var shouldSaveContent: Bool {
        return true
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.save-comment")
    }
    
    override var activityTitle: String? {
        return AWKLocalizedString("comment-save-activity-title")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "save_activity_icon")
    }
    
}

final class UnsaveCommentActivity: SaveContentActivity<Comment> {
    
    override internal var shouldSaveContent: Bool {
        return false
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.unsave-comment")
    }
    
    override var activityTitle: String? {
        return AWKLocalizedString("comment-unsave-activity-title")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "unsave_activity_icon")
    }
    
}
