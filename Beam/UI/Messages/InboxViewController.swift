//
//  InboxViewController.swift
//  beam
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData
import Trekker

class InboxViewController: BeamViewController {
    
    var messagesViewController: MessagesViewController {
        return self.childViewControllers.first(where: { (childViewController) -> Bool in
            return childViewController is MessagesViewController
        }) as! MessagesViewController
    }
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var buttonBarItem: UIBarButtonItem!
    @IBOutlet weak var buttonBar: ButtonBar!

    fileprivate var isMarkingMessagesAsRead = false {
        didSet {
            if self.isMarkingMessagesAsRead {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            } else {
                self.reloadMarkAllMessagesReadButton()
            }
        }
    }
    
    /// To make sure the "View inbox" event is only tracked once upon viewDidAppear.
    var viewInboxEventTracked: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.messagesViewController.viewType = .notifications
        
        self.navigationItem.title = AWKLocalizedString("messages-title")
        
        self.messagesViewController.delegate = self

        self.reloadBadgeIcons()
        
        self.buttonBar.addTarget(self, action: #selector(InboxViewController.buttonBarChanged(_:)), for: UIControlEvents.valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(InboxViewController.messageDidChangeUnreadState(_:)), name: .RedditMessageDidChangeUnreadState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(InboxViewController.userDidUpdate(notification:)), name: AuthenticationController.UserDidUpdateNotificationName, object: nil)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "mark-all-as-read"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(InboxViewController.markAllMessagesAsReadTapped(_:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.reloadBadgeIcons()
        self.reloadMarkAllMessagesReadButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.viewInboxEventTracked {
            Trekker.default.track(event: TrekkerEvent(event: "View inbox", properties: ["View": self.messagesViewController.viewType.analyticsName]))
            self.viewInboxEventTracked = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func userDidUpdate(notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.reloadMarkAllMessagesReadButton()
        }
    }
    
    @objc fileprivate func messageDidChangeUnreadState(_ sender: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.reloadBadgeIcons()
        }
    }
    
    fileprivate func reloadMarkAllMessagesReadButton() {
        let objectContext = AppDelegate.shared.managedObjectContext!
        if let user = AppDelegate.shared.authenticationController.activeUser(objectContext) {
            self.navigationItem.rightBarButtonItem?.isEnabled = user.hasMail.boolValue && self.isMarkingMessagesAsRead == false
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    fileprivate func reloadBadgeIcons() {
        do {
            let objectContext = AppDelegate.shared.managedObjectContext!
            
            let messagesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.entityName())
            messagesFetchRequest.predicate = NSPredicate(format: "unread == YES && reference == nil")
            messagesFetchRequest.fetchLimit = 1
            let unreadMessages = try objectContext.fetch(messagesFetchRequest).count > 0
            
            let notificationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.entityName())
            notificationsFetchRequest.predicate = NSPredicate(format: "unread == YES && reference != nil")
            notificationsFetchRequest.fetchLimit = 1
            let unreadNotifications = try objectContext.fetch(notificationsFetchRequest).count > 0
            
            if unreadMessages || unreadNotifications {
                AppDelegate.shared.updateMessagesState()
            }
            
            self.buttonBar.items = [ButtonBarButton(title: AWKLocalizedString("notifications"), showsBadge: unreadNotifications), ButtonBarButton(title: AWKLocalizedString("inbox"), showsBadge: unreadMessages), ButtonBarButton(title: AWKLocalizedString("sent"), showsBadge: false)]
        } catch {
            
        }
        
    }
    
    @objc fileprivate func buttonBarChanged(_ sender: ButtonBar) {
        if sender.selectedItemIndex == 1 {
            self.messagesViewController.viewType = .messages
        } else if sender.selectedItemIndex == 2 {
            self.messagesViewController.viewType = .sent
        } else {
            self.messagesViewController.viewType = .notifications
        }
        Trekker.default.track(event: TrekkerEvent(event: "View inbox", properties: ["View": self.messagesViewController.viewType.analyticsName]))
        if let splitViewController = self.splitViewController, let blankViewController = self.storyboard?.instantiateViewController(withIdentifier: "messages-blank-view"), splitViewController.viewControllers.count > 1 {
            if let navigationController = self.splitViewController?.viewControllers.last as? UINavigationController {
                navigationController.viewControllers = [blankViewController]
            } else {
                let navigationController = BeamColorizedNavigationController(rootViewController: blankViewController)
                splitViewController.viewControllers = [splitViewController.viewControllers.first!, navigationController]
            }
        }

    }
    
    @objc fileprivate func markAllMessagesAsReadTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("mark-all-messages-as-read-alert-message", comment: "The message on the alert to ask if you are you you want to mark all messages as read"), preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("mark-as-read-action-title", comment: "The title of the mark as read action"), style: .default, handler: { (_) in
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.isMarkingMessagesAsRead = true
            let operation = Message.markAllAsReadOperation(authenticationController: AppDelegate.shared.authenticationController, managedObjectContext: AppDelegate.shared.managedObjectContext)
            DataController.shared.executeAndSaveOperations([operation], handler: { (error) in
                DispatchQueue.main.async {
                    if error != nil {
                        self.presentErrorMessage(NSLocalizedString("mark-all-messages-read-error", comment: "Error when there was an error marking all messages as read"))
                        self.reloadBadgeIcons()
                    } else {
                        self.messagesViewController.tableView.reloadData()
                        AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.hasMail = false
                        AppDelegate.shared.updateMessagesState()
                        self.reloadBadgeIcons()
                        
                    }
                    self.isMarkingMessagesAsRead = false
                }
            })
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.buttonBarItem.width = self.view.bounds.width
    }

}

extension InboxViewController: MessagesViewControllerDelegate {
    
    func messagesViewController(_ viewController: MessagesViewController, didChangeContent content: [Content]?) {
        self.reloadBadgeIcons()
    }
}

// MARK: - NavigationBarNotificationDisplayingDelegate

extension InboxViewController: NavigationBarNotificationDisplayingDelegate {
    
    func topViewForDisplayOfnotificationView<NotificationView: UIView>(_ view: NotificationView) -> UIView? where NotificationView: NavigationBarNotification {
        return self.buttonBar.superview
    }
}

// MARK: - InboxViewController
extension InboxViewController: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
}
