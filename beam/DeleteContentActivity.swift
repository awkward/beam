//
//  DeleteContentActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 04-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

internal class DeleteContentActivity: UIActivity {
    
    internal var content: Content?
    
    internal var contentType: String {
        return "content"
    }
    
    override var activityType : UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.delete-\(self.contentType)")
    }
    
    override var activityTitle : String? {
        return AWKLocalizedString("delete-\(self.contentType)-activity-title")
    }
    
    override var activityImage : UIImage? {
        return UIImage(named: "delete_\(self.contentType)_activity_icon")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard AppDelegate.shared.authenticationController.isAuthenticated == true else {
            return false
        }
        if let username = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username {
            for item in activityItems {
                if let content = item as? Content , content.author == username && content.objectName != nil && content.hasBeenDeleted == false {
                    return true
                }
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if item is Content {
                self.content = item as? Content
            }
        }
    }
    
    override var activityViewController : UIViewController? {

        let alertController = BeamAlertController(title: AWKLocalizedString("delete-\(self.contentType)-title"), message: AWKLocalizedString("delete-\(self.contentType)-message"), preferredStyle: UIAlertControllerStyle.alert)
        alertController.addCancelAction()
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("delete-button"), style: UIAlertActionStyle.destructive, handler: { (action) in
            if AppDelegate.shared.authenticationController.isAuthenticated {
                if let content = self.content {
                    let operations = content.deleteOperations(AppDelegate.shared.authenticationController)
                    DataController.shared.executeAndSaveOperations(operations, context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                        DispatchQueue.main.async(execute: { () -> Void in
                            if let comment: Comment = self.content as? Comment {
                                comment.author = "[deleted]"
                                comment.content = "[deleted]"
                                comment.authorFlairText = nil
                                comment.markdownString = nil
                            }
                            
                            NotificationCenter.default.post(name: .ContentDidDelete, object: self.content)
                            
                            self.activityDidFinish(true)
                            if error != nil {
                                AppDelegate.topViewController()?.present(BeamAlertController(alertWithCloseButtonAndTitle: AWKLocalizedString("delete--\(self.contentType)-error"), message: AWKLocalizedString("delete-\(self.contentType)-error-message")), animated: true, completion: nil)
                            }
                        })
                    })
                }
            }
        }))
        return alertController
    }
}

class DeletePostActivity: DeleteContentActivity {
    
    internal override var contentType: String {
        return "post"
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard super.canPerform(withActivityItems: activityItems) == true else {
            return false
        }
        for item in activityItems {
            if item is Post {
                return true
            }
        }
        return false
    }
}

class DeleteCommentActivity: DeleteContentActivity {
    
    internal override var contentType: String {
        return "comment"
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard super.canPerform(withActivityItems: activityItems) == true else {
            return false
        }
        for item in activityItems {
            if item is Comment {
                return true
            }
        }
        return false
    }
}
