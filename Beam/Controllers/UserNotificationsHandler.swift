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
import UserNotifications

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
    case ShowView = "show_view"
}

final class UserNotificationsHandler: NSObject {
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        
        let messageReplyAction = UNTextInputNotificationAction(identifier: "reply_message", title: NSLocalizedString("notif-act-reply", comment: "The title of the \"Reply\" action on a notification"), options: [])
        let messageCategory = UNNotificationCategory(identifier: "reddit_message", actions: [messageReplyAction], intentIdentifiers: [], options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories(Set([messageCategory]))
    }
    
    public func registerForUserNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (_, _) in
            
        }
    }
    
    // MARK: - Notification actions
    
    fileprivate func scheduleFailedMessageNotification() {
        let content = UNMutableNotificationContent()
        content.body = AWKLocalizedString("notif-message-failed-message")
        content.title = AWKLocalizedString("notif-message-failed")
        content.sound = UNNotificationSound.default()
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // MARK: - Notification handling
    
    func handleNotification(_ notification: UNNotification) {
        self.handleNotificationContent(notification.request.content)
    }
    
    func handleNotificationContent(_ content: UNNotificationContent) {
        Trekker.default.track(event: TrekkerEvent(event: "Open notification"))
        guard let customInfo = content.userInfo[UserNotificationCustomBodyKey] as? [AnyHashable: Any], let actionKey = customInfo[UserNotificationCustomBodyKeys.Action.rawValue] as? String, let action = UserNotificationActionKey(rawValue: actionKey) else {
            AWKDebugLog("No action required for this notification or unsupported action")
            return
        }
        Trekker.default.track(event: TrekkerEvent(event: "Open notification", properties: ["Action": action.rawValue]))
        
        var notificationURL: URL?
        if let urlString = customInfo[UserNotificationCustomBodyKeys.URL.rawValue] as? String {
            if urlString == "[update]" || urlString == "[appstore]" {
                notificationURL = BeamAppStoreURL
            } else if urlString == "[review]" {
                notificationURL = BeamAppStoreReviewURL
            } else {
                notificationURL = URL(string: urlString)
            }
        }
        
        switch action {
        case UserNotificationActionKey.DirectToURL:
            if let openURL = notificationURL {
                UIApplication.shared.open(openURL, options: [:], completionHandler: nil)
            }
        case UserNotificationActionKey.ShowAlert:
            self.handleShowAlert(content, customInfo: customInfo, detailURL: notificationURL)
        case UserNotificationActionKey.ShowURL:
            self.handleShowURL(notificationURL)
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
        case UserNotificationActionKey.ShowView:
            self.handleShowView(customInfo)
        }
    }
    
    fileprivate func handleShowAlert(_ content: UNNotificationContent, customInfo: [AnyHashable: Any]?, detailURL: URL?) {
        var alertTitle = AWKLocalizedString("alert")
        if let title = customInfo?[UserNotificationCustomBodyKeys.Title.rawValue] as? String {
            alertTitle = title
        } else {
            alertTitle = content.title
        }
        
        var alertMessage = content.body
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
        if detailURL == nil {
            alertDetailButton = nil
        }
        
        let alertController = BeamAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: alertCancelButton, style: UIAlertActionStyle.cancel, handler: nil))
        
        if let detailURL = detailURL, alertDetailButton != nil {
            let detailAction = UIAlertAction(title: alertDetailButton, style: UIAlertActionStyle.default, handler: { (_) -> Void in
                UIApplication.shared.open(detailURL, options: [:], completionHandler: nil)
            })
            alertController.addAction(detailAction)
        }
        
        AppDelegate.topViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func handleShowURL(_ url: URL?) {
        if let url = url {
            AppDelegate.topViewController()?.present(BeamSafariViewController(url: url), animated: true, completion: nil)
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
            MessagesViewController.fetchComment(comment.objectName!, handler: { (comment, _) in
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
    
    // MARK: - View Controllers
    
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
    
    // MARK: - Objects
    
    fileprivate func objectFromCustomInfo(_ customInfo: [AnyHashable: Any]) -> SyncObject? {
        guard let objectInfo = customInfo[UserNotificationCustomBodyKeys.Object.rawValue] as? NSDictionary, let name = objectInfo["name"] as? String else {
            return nil
        }
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
        return nil
    }
    
    func handleReplyMessageNotificationResponse(_ response: UNTextInputNotificationResponse, completionHandler: @escaping () -> Void) {
        guard let customBody = response.notification.request.content.userInfo[UserNotificationCustomBodyKeys.Object.rawValue] as? [AnyHashable: Any], let parentMessageIdentifier = customBody["name"] as? String else {
            print("Missing parent message identifier")
            completionHandler()
            return
        }
        // Handle a raply to a message!
        do {
            let message = try Message.objectWithIdentifier(parentMessageIdentifier, cache: nil, context: AppDelegate.shared.managedObjectContext) as! Message
            
            let operations = message.replyOperations(response.userText, authenticationcontroller: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations(operations, handler: { (_) -> Void in
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
    }

}

extension UserNotificationsHandler: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //If we receive the notification while the app is in the foreground, we still show it!
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // The notification was tapped
            guard AppDelegate.shared.isWindowUsable else {
                AppDelegate.shared.scheduleAppAction(.handleNotification(notification: response.notification))
                completionHandler()
                return
            }
            self.handleNotification(response.notification)
            completionHandler()
        case "reply_message":
            guard let textResponse = response as? UNTextInputNotificationResponse else {
                print("No text response found for action that requires text response")
                completionHandler()
                return
            }
            handleReplyMessageNotificationResponse(textResponse, completionHandler: completionHandler)
        default:
            print("Unsupported notification action: \(response.actionIdentifier)")
            completionHandler()
        }
        
    }
    
}
