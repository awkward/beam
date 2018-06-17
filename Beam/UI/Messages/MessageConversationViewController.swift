//
//  MessageConversationViewController.swift
//  beam
//
//  Created by Robin Speijer on 17-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import TTTAttributedLabel
import Trekker

private let MaxChildRepliesPerLevel = [Int.max, 2, 0]

class MessageConversationViewController: BeamViewController {

    var message: Message? {
        didSet {
            guard self.isViewLoaded else {
                return
            }
            
            self.reloadContent()
        }
    }
    
    var sentMessage: Bool = false
    
    fileprivate var messageList: [Message]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    lazy var replyBar: ReplyBarView = {
        let bar = ReplyBarView.loadFromNib(self.message?.author, delegate: self)
        return bar
    }()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var headerView: MessageHeaderView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 119

        self.title = NSLocalizedString("message", comment: "Message title")
        self.reloadContent()
        
        if !self.sentMessage {
            self.replyBar.addToViewController(self)
        }
        
        if let username = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username, let author = self.message?.author, author != username {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "message_action_more"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageConversationViewController.moreTapped(_:)))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let message = self.message {
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
    }
    
    // MARK: - Content
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        switch self.displayMode {
        case .default:
            self.tableView.backgroundColor = UIColor.white
        case .dark:
            self.tableView.backgroundColor = UIColor.beamDarkContentBackgroundColor()
        }
    }
    
    fileprivate func reloadContent() {
        self.headerView.message = self.message
        self.view.setNeedsLayout()
        
        if let message = self.message {
            self.messageList = [message]
        } else {
            self.messageList = nil
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate headerview size
        let maxTextSize = UIEdgeInsetsInsetRect(self.view.bounds, self.headerView.layoutMargins).size
        self.headerView.titleLabel.preferredMaxLayoutWidth = maxTextSize.width
        self.headerView.dateLabel.preferredMaxLayoutWidth = maxTextSize.width
        let size = self.headerView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: self.view.bounds.height), withHorizontalFittingPriority: UILayoutPriority.fittingSizeLevel, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
        self.headerView.frame = CGRect(origin: CGPoint(), size: size)
        
        self.tableView.tableHeaderView = nil
        self.tableView.tableHeaderView = self.headerView
        
        self.tableView.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 0 + self.replyBar.bounds.height, right: 0)
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if let splitViewController = self.splitViewController, let navigationController = self.navigationController, navigationController.viewControllers.count <= 1 {
            self.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    // MARK: - Actions
    
    @objc fileprivate func moreTapped(_ sender: UIBarButtonItem) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("delete-message-action-title", comment: "The action to delete a message on the message detail view"), style: UIAlertActionStyle.destructive, handler: { (_) in
            guard let message: Message = self.message, message.identifier != nil else {
                return
            }
            let operation: Operation = message.deleteOperation(AppDelegate.shared.authenticationController, managedObjectContext: AppDelegate.shared.managedObjectContext)
            DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if let error = error as NSError? {
                        if error.code == NSURLErrorNotConnectedToInternet && error.domain == NSURLErrorDomain {
                            self.presentErrorMessage(NSLocalizedString("error-delete-message-internet", comment: "Internet connection error while deleting message"))
                        } else {
                            self.presentErrorMessage(NSLocalizedString("error-delete-message", comment: "General error deleting message"))
                        }
                    } else {
                        _ = self.navigationController?.popToRootViewController(animated: true)
                    }
                })
            })
        }))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel-action-title", comment: "The action cancel a alert or actionsheet"), style: UIAlertActionStyle.cancel, handler: nil))
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}

extension MessageConversationViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "message") as! MessageDetailCell
        cell.sentMessage = self.sentMessage
        cell.message = self.messageList?[indexPath.row]
        cell.delegate = self
        cell.contentLabel.delegate = self
        return cell
    }
    
}

extension MessageConversationViewController: MessageObjectCellDelegate {

    func messageObjectCell(_ cell: MessageObjectCell, didTapUsernameOnMessage message: Message) {
        if let username = self.sentMessage ? message.destination: message.author, username != "[deleted]" {
            let navigationController = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as! BeamColorizedNavigationController
            let profileViewController = navigationController.viewControllers.first as! ProfileViewController
            profileViewController.username = username
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
}

extension MessageConversationViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if ExternalLinkOpenOption.shouldShowPrivateBrowsingWarning() {
            ExternalLinkOpenOption.showPrivateBrowsingWarning(url, on: self)
        } else {
            if let viewController = AppDelegate.shared.openExternalURLWithCurrentBrowser(url) {
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
}

extension MessageConversationViewController: ReplyBarViewDelegate {
    
    func replyBar(_ replyBarView: ReplyBarView, didTapSendMessage content: String) {
        replyBarView.clear()
        _ = replyBarView.resignFirstResponder()
        if let message = self.message, content.count > 0 {
            self.replyBar.sending = true
            let operations = message.replyOperations(content, authenticationcontroller: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations(operations, context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                //Message read statuses are not that important that it needs to display the error message to the user
                DispatchQueue.main.async(execute: { () -> Void in
                    self.replyBar.sending = false
                    if let error = error {
                        AWKDebugLog("Message reply error: \(error)")
                        self.presentErrorMessage(AWKLocalizedString("message-sent-failed"))
                        replyBarView.text = content
                    } else {
                        self.presentSuccessMessage(AWKLocalizedString("message-sent-sucessfully"))
                        Trekker.default.track(event: TrekkerEvent(event: "Send reddit message", properties: ["Type": "Reply"]))
                    }
                })
                
            })
        }
        
    }
}
