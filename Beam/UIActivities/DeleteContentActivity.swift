//
//  DeleteContentActivity.swift
//  Beam
//
//  Created by Rens Verhoeven on 04-04-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

internal class DeleteContentActivity<T: Content>: CustomObjectActivity<T> {
    
    internal var contentType: String {
        return "content"
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "com.madeawkward.beam.delete-\(self.contentType)")
    }
    
    override var activityTitle: String? {
        return AWKLocalizedString("delete-\(self.contentType)-activity-title")
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "delete_\(self.contentType)_activity_icon")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard AppDelegate.shared.authenticationController.isAuthenticated == true, let content = self.firstObject(in: activityItems), let username = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username else {
            return false
        }
        return  content.author == username && content.objectName != nil && content.hasBeenDeleted == false
    }
    
    override var activityViewController: UIViewController? {
        guard AppDelegate.shared.authenticationController.isAuthenticated, let content = self.object else {
            return nil
        }
        let alertController = BeamAlertController(title: AWKLocalizedString("delete-\(self.contentType)-title"), message: AWKLocalizedString("delete-\(self.contentType)-message"), preferredStyle: UIAlertControllerStyle.alert)
        alertController.addCancelAction()
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("delete-button"), style: UIAlertActionStyle.destructive, handler: { (_) in
            let operations = content.deleteOperations(AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations(operations, context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if let comment: Comment = content as? Comment {
                        comment.author = "[deleted]"
                        comment.content = "[deleted]"
                        comment.authorFlairText = nil
                        comment.markdownString = nil
                    }
                    
                    NotificationCenter.default.post(name: .ContentDidDelete, object: content)
                    
                    self.activityDidFinish(true)
                    if error != nil {
                        AppDelegate.topViewController()?.present(BeamAlertController(alertWithCloseButtonAndTitle: AWKLocalizedString("delete--\(self.contentType)-error"), message: AWKLocalizedString("delete-\(self.contentType)-error-message")), animated: true, completion: nil)
                    }
                })
            })
        }))
        return alertController
    }
}

final class DeletePostActivity: DeleteContentActivity<Post> {
    
    internal override var contentType: String {
        return "post"
    }

}

final class DeleteCommentActivity: DeleteContentActivity<Comment> {
    
    internal override var contentType: String {
        return "comment"
    }

}
