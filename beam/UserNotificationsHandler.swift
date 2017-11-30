//
//  UserNotificationsHandler.swift
//  Beam
//
//  Created by Rens Verhoeven on 08-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import CoreData
import Snoo
import CherryKit
import Trekker

let UserNotificationCustomBodyKey = "beam"

enum UserNotificationCustomBodyKeys: String {
    case Action = "action"
    case URL = "url"
    case CancelButtton = "camcel_button"
    case DetailButton = "detail_button"
    case Message = "message"
    case Title = "title"
    case Object = "object"
    case View = "view"
    case Product = "product"
}

enum UserNotificationActionKey: String {
    case DirectToURL = "direct_to_url"
    case ShowAlert = "show_alert"
    case ShowURL = "show_url"
    case ShowSubreddit = "show_subreddit"
    case ShowPost = "show_post"
    case ShowMessage = "show_message"
    case ShowThread = "show_thread"
    case ShowUserProfile = "show_profile"
    case ShowStore = "show_store"
    case ShowView = "show_view"
}

private struct NotificationBody {
    let alertTitle: String?
    let alertBadge: NSNumber?
    let alertBody: String?
    let category: String?
}

final class UserNotificationsHandler: NSObject {
    
    //MARK: - Notification actions
    
    func handleNotificationAction(_ identifier: String?, forLocalNotification notification: UILocalNotification, withResponseInfo responseInfo: [AnyHashable: Any]?, completionHandler: @escaping () -> Void) {
        self.handleNotificationAction(identifier, customInfo: notification.userInfo?[UserNotificationCustomBodyKey] as? [AnyHashable: Any], responseInfo: responseInfo, completionHandler: completionHandler)
    }
    
    func handleNotificationAction(_ identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any], withResponseInfo responseInfo: [AnyHashable: Any]?, completionHandler: @escaping () -> Void) {
        self.handleNotificationAction(identifier, customInfo: userInfo[UserNotificationCustomBodyKey] as? [AnyHashable: Any], responseInfo: responseInfo, completionHandler: completionHandler)
    }
    
    fileprivate func handleNotificationAction(_ identifier: String?, customInfo: [AnyHashable: Any]?, responseInfo: [AnyHashable: Any]?, completionHandler: @escaping () -> Void) {
        guard identifier != nil else {
            completionHandler()
            return
        }
        if let identifier = identifier {
            //Inline reply to messages is only available in iOS 9+. If we can't use it just call the completionHandler.
            if let customInfo = customInfo,
                let responseInfo = responseInfo,
                let messageReply = responseInfo[UIUserNotificationActionResponseTypedTextKey] as? String,
                let parentMessageObjectInformation = customInfo[UserNotificationCustomBodyKeys.Object.rawValue] as? [AnyHashable: Any],
                let parentMessageIdentifier = parentMessageObjectInformation["name"] as? String
                , identifier == "reply_message" {
                //The user replied to a message
                do {
                    let message = try Message.objectWithIdentifier(parentMessageIdentifier, cache: nil, context: AppDelegate.shared.managedObjectContext) as! Message
                    
                    let operations = message.replyOperations(messageReply, authenticationcontroller: AppDelegate.shared.authenticationController)
                    DataController.shared.executeAndSaveOperations(operations, handler: { (error) -> Void in
                        //Warn the user the message failed
                        self.scheduleFailedMessageNotification()
                        DispatchQueue.main.async {
                            completionHandler()
                        }
                    })
                    //As an extra mark the message as read, but we don't care if it fails.
                    let markReadOperation = message.markReadOperation(true, authenticationController: AppDelegate.shared.authenticationController)
                    DataController.shared.executeAndSaveOperations([markReadOperation], handler: nil)
                } catch {
                    //Warn the user the message failed
                    self.scheduleFailedMessageNotification()
                    completionHandler()
                }
                return
            }
            
            AWKDebugLog("Unsupported notification action: %@", identifier)
            completionHandler()
        }
        
    }
    
    fileprivate func scheduleFailedMessageNotification() {
        let notification = UILocalNotification()
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.alertTitle = AWKLocalizedString("notif-message-failed")
        notification.alertBody = AWKLocalizedString("notif-message-failed-message")
        notification.fireDate = Date()
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    //MARK: - Notification handling
    
    func handleBannerNotification(_ notification: BannerNotification) {
        self.handleNotification(nil, customInfo: notification.customInfo, userInfo: nil)
    }
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        Trekker.default.trackPushNotificationOpen(userInfo)
        self.handleNotification(self.notificationBodyFromRemoteNotification(userInfo), customInfo: userInfo[UserNotificationCustomBodyKey] as? [AnyHashable: Any], userInfo: userInfo)
    }
    
    fileprivate func notificationBodyFromRemoteNotification(_ userInfo: [AnyHashable: Any]) -> NotificationBody {
        if let aps = userInfo["aps"] as? [String : AnyObject] {
            var alertTitle: String?
            var alertBody: String?
            let alertBadge = aps["badge"] as? NSNumber
            let category = aps["category"] as? String
            if let alert = userInfo["alert"] as? [String : AnyObject] {
                alertTitle = alert["title"] as? String
                alertBody = alert["body"] as? String
            } else {
                alertBody = aps["alert"] as? String
            }
            return NotificationBody(alertTitle: alertTitle, alertBadge: alertBadge, alertBody: alertBody, category: category)
        }
        return NotificationBody(alertTitle: nil, alertBadge: nil, alertBody: nil, category: nil)
       
    }
    
    func handleLocalNotification(_ notification: UILocalNotification) {
        let body = NotificationBody(alertTitle: notification.alertTitle, alertBadge: notification.applicationIconBadgeNumber as NSNumber?, alertBody: notification.alertBody, category: notification.category)
        self.handleNotification(body, customInfo: notification.userInfo?[UserNotificationCustomBodyKey] as? [AnyHashable: Any], userInfo: notification.userInfo)
    }
    
    fileprivate func handleNotification(_ notificationBody: NotificationBody?, customInfo: [AnyHashable: Any]?, userInfo: [AnyHashable: Any]?) {
        if let actionKey = customInfo?[UserNotificationCustomBodyKeys.Action.rawValue] as? String, let action = UserNotificationActionKey(rawValue: actionKey) {
            Trekker.default.track(event: TrekkerEvent(event: "Open notification", properties: ["Action": action.rawValue]))
            
            var URL: Foundation.URL?
            if let URLString = customInfo?[UserNotificationCustomBodyKeys.URL.rawValue] as? String {
                if URLString == "[update]" || URLString == "[appstore]" {
                    URL = BeamAppStoreURL as URL?
                } else if URLString == "[review]" {
                    URL = BeamAppStoreReviewURL as URL?
                } else {
                    URL = Foundation.URL(string: URLString)
                }
            }
            
            switch action {
            case UserNotificationActionKey.DirectToURL:
                if let URL = URL {
                    UIApplication.shared.openURL(URL)
                }
            case UserNotificationActionKey.ShowAlert:
                self.handleShowAlert(notificationBody, customInfo: customInfo, possibleURL: URL)
            case UserNotificationActionKey.ShowURL:
                self.handleShowURL(URL)
            case UserNotificationActionKey.ShowMessage:
                self.handleShowMessage(customInfo)
            case UserNotificationActionKey.ShowSubreddit:
                self.handleShowSubreddit(customInfo)
            case UserNotificationActionKey.ShowThread:
                self.handleShowThread(customInfo)
            case UserNotificationActionKey.ShowUserProfile:
                self.handleShowUserProfile(customInfo)
            case UserNotificationActionKey.ShowPost:
                self.handleShowPost(customInfo)
            case UserNotificationActionKey.ShowStore:
                self.handleShowStore(customInfo)
            case UserNotificationActionKey.ShowView:
                self.handleShowView(customInfo)
            }
        } else {
            Trekker.default.track(event: TrekkerEvent(event: "Open notification"))
            AWKDebugLog("No action required for this notification or unsupported action")
        }
    }
    
    fileprivate func handleShowAlert(_ notificationBody: NotificationBody?, customInfo: [AnyHashable: Any]?, possibleURL: URL?) {
        var alertTitle = AWKLocalizedString("alert")
        if let title = customInfo?[UserNotificationCustomBodyKeys.Title.rawValue] as? String {
            alertTitle = title
        } else if let title = notificationBody?.alertTitle {
            alertTitle = title
        }
        
        var alertMessage = notificationBody?.alertBody
        if let message = customInfo?[UserNotificationCustomBodyKeys.Message.rawValue] as? String {
            alertMessage = message
        }
        
        var alertCancelButton = AWKLocalizedString("cancel")
        if let alertButton = customInfo?[UserNotificationCustomBodyKeys.CancelButtton.rawValue] as? String {
            alertCancelButton = alertButton
        }
        
        var alertDetailButton: String? = AWKLocalizedString("details")
        if let alertButton = customInfo?[UserNotificationCustomBodyKeys.DetailButton.rawValue] as? String {
            alertDetailButton = alertButton
        }
        if possibleURL == nil {
            alertDetailButton = nil
        }
        
        let alertController = BeamAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: alertCancelButton, style: UIAlertActionStyle.cancel, handler: nil))
        
        if alertDetailButton != nil {
            let detailAction = UIAlertAction(title: alertDetailButton, style: UIAlertActionStyle.default, handler: { (action) -> Void in
                UIApplication.shared.openURL(possibleURL!)
            })
            alertController.addAction(detailAction)
        }
        
        AppDelegate.topViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func handleShowURL(_ URL: Foundation.URL?) {
        if let URL = URL {
            AppDelegate.topViewController()?.present(BeamSafariViewController(url: URL), animated: true, completion: nil)
        }
    }
    
    fileprivate func handleShowMessage(_ customInfo: [AnyHashable: Any]?) {
        AppDelegate.shared.changeActiveTabContent(AppTabContent.MessagesNavigation)
        if let customInfo = customInfo,
            let navigationController = AppDelegate.shared.tabBarController?.selectedViewController,
            let message = self.objectFromCustomInfo(customInfo) as? Message {
                if message.reference == nil {
                    if let messageViewController = navigationController.storyboard?.instantiateViewController(withIdentifier: "messageConversation") as? MessageConversationViewController {
                        messageViewController.message = message
                        navigationController.show(messageViewController, sender: nil)
                    }
                } else {
                    if message.unread == true {
                        message.unread = false
                        let operation = message.markReadOperation(true, authenticationController: AppDelegate.shared.authenticationController)
                        DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                            //Message read statuses are not that important that it needs to display the error message to the user
                            if let error = error {
                                AWKDebugLog("Message read status error: \(error)")
                            } else {
                                NotificationCenter.default.post(name: .RedditMessageDidChangeUnreadState, object: message)
                            }
                        })
                    }
                    if let post = message.reference as? Post {
                        self.showPostViewController(post)
                    } else if let comment = message.reference as? Comment {
                        self.showCommentThreadViewController(comment)
                    }
                }
        }
    }
    
    fileprivate func handleShowSubreddit(_ customInfo: [AnyHashable: Any]?) {
        if let customInfo = customInfo, let subreddit = self.objectFromCustomInfo(customInfo) as? Subreddit {
            
            //Open the subreddit
            let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
            if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
                tabBarController.subreddit = subreddit
                AppDelegate.topViewController()?.present(tabBarController, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func handleShowUserProfile(_ customInfo: [AnyHashable: Any]?) {
        if let userInfo = customInfo?[UserNotificationCustomBodyKeys.Object.rawValue] as? [AnyHashable: Any], let username = userInfo["username"] as? String {
            //Show profile
            let navigationController = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as! BeamColorizedNavigationController
            let profileViewController = navigationController.viewControllers.first as! ProfileViewController
            profileViewController.username = username
            AppDelegate.topViewController()?.present(navigationController, animated: true, completion: nil)
        } else {
            AppDelegate.shared.changeActiveTabContent(AppTabContent.ProfileNavigation)
        }
    }
    
    fileprivate func handleShowPost(_ customInfo: [AnyHashable: Any]?) {
        if let customInfo = customInfo, let post = self.objectFromCustomInfo(customInfo) as? Post {
            self.showPostViewController(post)
        }
    }
    
    fileprivate func handleShowThread(_ customInfo: [AnyHashable: Any]?) {
        AppDelegate.shared.changeActiveTabContent(AppTabContent.MessagesNavigation)
        if let customInfo = customInfo, let comment = self.objectFromCustomInfo(customInfo) as? Comment {
            MessagesViewController.fetchComment(comment.objectName!, handler: { (comment, error) -> () in
                DispatchQueue.main.async(execute: { () -> Void in
                    let commentsStoryboard = UIStoryboard(name: "Comments", bundle: nil)
                    let viewController = commentsStoryboard.instantiateViewController(withIdentifier: "comments") as! CommentsViewController
                    
                    let childQuery = CommentCollectionQuery()
                    childQuery.parentComment = comment
                    
                    viewController.query = childQuery
                    
                    let navigationController = CommentsNavigationController(rootViewController: viewController)
                    AppDelegate.topViewController()?.present(navigationController, animated: true, completion: nil)
                })
            })
            
        }
    }
    
    fileprivate func handleShowView(_ customInfo: [AnyHashable: Any]?) {
        if let viewKey = customInfo?[UserNotificationCustomBodyKeys.View.rawValue] as? String {
            if viewKey == "settings" {
                let upgradeStoryboard = UIStoryboard(name: "Settings", bundle: nil)
                if let viewController = upgradeStoryboard.instantiateInitialViewController() {
                    AppDelegate.topViewController()?.present(viewController, animated: true, completion: nil)
                }
            } else if viewKey == "donate" || viewKey == "donation" {
                let upgradeStoryboard = UIStoryboard(name: "Settings", bundle: nil)
                if let navigationController = upgradeStoryboard.instantiateInitialViewController() as? UINavigationController {
                    AppDelegate.topViewController()?.present(navigationController, animated: true, completion: nil)
                    navigationController.pushViewController(upgradeStoryboard.instantiateViewController(withIdentifier: "donation"), animated: false)
                }
            }
        }
    }
    
    fileprivate func handleShowStore(_ customInfo: [AnyHashable: Any]?) {
        let upgradeStoryboard = UIStoryboard(name: "Store", bundle: nil)
        if let navigationController = upgradeStoryboard.instantiateInitialViewController() as? UINavigationController {
            AppDelegate.topViewController()?.present(navigationController, animated: true, completion: nil)
            if let productInformation = customInfo?[UserNotificationCustomBodyKeys.Product.rawValue] as? [AnyHashable: Any], let identifier = productInformation["id"] as? String, let productViewController = upgradeStoryboard.instantiateViewController(withIdentifier: "productView") as? ProductViewController {
                productViewController.product = StoreProduct(identifier: identifier)
                navigationController.show(productViewController, sender: nil)
            }
        }
        
    }
    
    //MARK: - View Controllers
    
    fileprivate func showCommentThreadViewController(_ comment: Comment) {
        let commentsStoryboard = UIStoryboard(name: "Comments", bundle: nil)
        let viewController = commentsStoryboard.instantiateViewController(withIdentifier: "comments") as! CommentsViewController
        
        let childQuery = CommentCollectionQuery()
        childQuery.post = comment.post
        if let parentComment = comment.parent as? Comment {
            childQuery.parentComment = parentComment
        } else {
            childQuery.parentComment = comment
        }
        
        viewController.query = childQuery
        
        let navigationController = CommentsNavigationController(rootViewController: viewController)
        AppDelegate.topViewController()?.present(navigationController, animated: true, completion: nil)
    }
    
    fileprivate func showPostViewController(_ post: Post) {
        var postSubreddit = post.subreddit
        if postSubreddit == nil {
            do {
                postSubreddit = try Subreddit.frontpageSubreddit()
            } catch {
                
            }
        }
        //Open the subreddit
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
            tabBarController.subreddit = postSubreddit
            AppDelegate.topViewController()?.present(tabBarController, animated: true, completion: nil)
            
            let detailViewController = PostDetailViewController(postName: post.objectName!, contextSubreddit: postSubreddit)
            tabBarController.streamViewController?.navigationController?.show(detailViewController, sender: nil)
        }
        
        
    }
    
    //MARK: - Objects
    
    fileprivate func objectFromCustomInfo(_ customInfo: [AnyHashable: Any]) -> SyncObject? {
        if let objectInfo = customInfo[UserNotificationCustomBodyKeys.Object.rawValue] as? NSDictionary {
            if let name = objectInfo["name"] as? String {
                do {
                    if let objectType = try SyncObject.identifierAndTypeWithObjectName(name) {
                        if objectType.type == SyncObjectType.MessageType {
                            return try Message.objectWithDictionary(objectInfo, cache: nil, context: AppDelegate.shared.managedObjectContext)
                        } else if objectType.type == SyncObjectType.AccountType {
                            return try User.objectWithDictionary(objectInfo, cache: nil, context: AppDelegate.shared.managedObjectContext)
                        } else if objectType.type == SyncObjectType.CommentType {
                            return try Comment.objectWithDictionary(objectInfo, cache: nil, context: AppDelegate.shared.managedObjectContext)
                        } else if objectType.type == SyncObjectType.SubredditType {
                            return try Subreddit.objectWithDictionary(objectInfo, cache: nil, context: AppDelegate.shared.managedObjectContext)
                        } else if objectType.type == SyncObjectType.LinkType {
                            return try Post.objectWithDictionary(objectInfo, cache: nil, context: AppDelegate.shared.managedObjectContext)
                        }
                    }
                } catch {
                    AWKDebugLog("Failed to get object information for custom info")
                }
            }
        }
        return nil
    }

}
