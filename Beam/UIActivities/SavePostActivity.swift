//
//  SavePostActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 21-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

class SavePostActivity: UIActivity {
    
    internal var post: Post?
    
    internal var shouldSavePost: Bool {
        return true
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.save-post")
    }
    
    override var activityTitle : String? {
        return AWKLocalizedString("post-save-activity-title")
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "save_activity_icon")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        if AppDelegate.shared.authenticationController.isAuthenticated {
            for item in activityItems {
                if let post = item as? Post {
                    if post.isSaved.boolValue == !self.shouldSavePost {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        self.post = activityItems.compactMap({ (object) -> Post? in
            return object as? Post
        }).first
    }
    
    override func perform() {
        if AppDelegate.shared.authenticationController.isAuthenticated {
            if let post = self.post {
                post.isSaved = NSNumber(value: self.shouldSavePost)
                let operation = post.saveToRedditOperation(self.shouldSavePost, authenticationController: AppDelegate.shared.authenticationController)
                DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.activityDidFinish(true)
                        if error != nil {
                            let alertController = BeamAlertController(title: AWKLocalizedString("post-save-error"), message: AWKLocalizedString("post-save-error-message"), preferredStyle: .alert)
                            alertController.addCloseAction()
                            AppDelegate.topViewController()?.present(alertController, animated: true, completion: nil)
                        } else {
                            NotificationCenter.default.post(name: .ContentDidChangeSavedState, object: self.post)
                        }
                    })
                })
            }
        }
    }
    
}

class UnsavePostActivity: SavePostActivity {
    
    override internal var shouldSavePost: Bool {
        return false
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.unsave-post")
    }
    
    override var activityTitle : String? {
        return AWKLocalizedString("post-unsave-activity-title")
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "unsave_activity_icon")
    }
    
}
