//
//  SaveCommentActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 19-05-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

class SaveCommentActivity: UIActivity {
    
    internal var comment: Comment?
    
    internal var shouldSaveComment: Bool {
        return true
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.save-comment")
    }
    
    override var activityTitle : String? {
        return AWKLocalizedString("comment-save-activity-title")
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "save_activity_icon")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        if AppDelegate.shared.authenticationController.isAuthenticated {
            for item in activityItems {
                if let comment = item as? Comment , comment.hasBeenDeleted == false {
                    if comment.isSaved.boolValue == !self.shouldSaveComment {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if item is Comment {
                
                self.comment = item as? Comment
            }
        }
    }
    
    override func perform() {
        if AppDelegate.shared.authenticationController.isAuthenticated {
            if let comment = self.comment {
                comment.isSaved = NSNumber(value: self.shouldSaveComment)
                let operation = comment.saveToRedditOperation(self.shouldSaveComment, authenticationController: AppDelegate.shared.authenticationController)
                DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.activityDidFinish(true)
                        if error != nil {
                            let alertController = BeamAlertController(title: AWKLocalizedString("comment-save-error"), message: AWKLocalizedString("comment-save-error-message"), preferredStyle: .alert)
                            alertController.addCloseAction()
                            AppDelegate.topViewController()?.present(alertController, animated: true, completion: nil)
                        } else {
                            NotificationCenter.default.post(name: .ContentDidChangeSavedState, object: self.comment)
                        }
                    })
                })
            }
        }
    }
    
}

class UnsaveCommentActivity: SaveCommentActivity {
    
    override internal var shouldSaveComment: Bool {
        return false
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.unsave-comment")
    }
    
    override var activityTitle : String? {
        return AWKLocalizedString("comment-unsave-activity-title")
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "unsave_activity_icon")
    }
    
}
