//
//  MessagesTableViewController.swift
//  beam
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

enum MessagesViewType {
    case messages
    case notifications
    case sent
    
    var analyticsName: String {
        switch self {
        case .messages:
            return "Messages"
        case .notifications:
            return "Notifications"
        case .sent:
            return "Sent"
        }
    }
}

protocol MessageObjectCellDelegate: class {
    
    func messageObjectCell(_ cell: MessageObjectCell, didTapUsernameOnMessage message: Message)
    
}

protocol MessageObjectCell {
    var message: Message? { get set }
    var delegate: MessageObjectCellDelegate? { get set }
    
}

private let MessagesViewControllerShowMessageSegue = "showmessage"

protocol MessagesViewControllerDelegate: class {
    
    func messagesViewController(_ viewController: MessagesViewController, didChangeContent content: [Content]?)
}

class MessagesViewController: BeamTableViewController, BeamViewControllerLoading {
    
    @IBOutlet var loadingFooterView: LoaderFooterView!
    
    typealias CollectionItem = Content
    
    weak var delegate: MessagesViewControllerDelegate?
    
    let collectionController = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
    
    var viewType = MessagesViewType.messages {
        didSet {
            if self.viewType != oldValue || self.content == nil {
                self.collectionController.cancelFetching()
                self.defaultEmptyViewType = self.viewType == MessagesViewType.notifications ? BeamEmptyViewType.NoInboxNotifications: BeamEmptyViewType.NoInboxMessages
                self.content = nil
                let query = MessageCollectionQuery()
                query.messageBox = self.viewType == MessagesViewType.sent ? MessageBox.sent: MessageBox.inbox
                if self.viewType == .messages || self.viewType == .sent {
                    query.contentPredicate = NSPredicate(format: "reference == nil")
                } else {
                    query.contentPredicate = NSPredicate(format: "reference != nil")
                }
                
                self.collectionController.query = query
                self.startCollectionControllerFetching()
            }
            self.tableView.reloadData()
        }
    }
    
    var content: [Content]? {
        didSet {
            UIView.animate(withDuration: 0.32, animations: {
                self.tableView.tableFooterView?.frame = CGRect(origin: self.tableView.tableFooterView!.frame.origin, size: CGSize(width: self.tableView.bounds.width, height: 0))
                }, completion: { (_) in
                    self.tableView.tableFooterView = nil
            })
            self.tableView.reloadData()

            self.delegate?.messagesViewController(self, didChangeContent: self.content)
        }
    }
    
    var emptyView: BeamEmptyView? {
        didSet {
            self.tableView.backgroundView = emptyView
            self.tableView.separatorStyle = (emptyView == nil) ? .singleLine : .none
            self.refreshControl?.alpha = (self.emptyView?.emptyType == BeamEmptyViewType.Loading) ? 0: 1
            self.tableView.isScrollEnabled = self.emptyView == nil
            self.emptyView?.layoutMargins = self.tableView.contentInset
        }
    }
    
    var defaultEmptyViewType = BeamEmptyViewType.NoInboxMessages
    
    func emptyViewTypeForState(_ state: BeamViewControllerLoadingState) -> BeamEmptyViewType {
        if !AppDelegate.shared.authenticationController.isAuthenticated {
            return BeamEmptyViewType.MessagesNotLoggedIn
        }
        
        switch state {
        case .loading:
            return BeamEmptyViewType.Loading
        case .noInternetConnection:
            return BeamEmptyViewType.Error
        case .noAccess:
            return BeamEmptyViewType.MessagesNotLoggedIn
        default:
            return self.defaultEmptyViewType
        }
    }
    
    var loadingState = BeamViewControllerLoadingState.empty {
        didSet {
            if loadingState != .loading {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Subscribe to notifications
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.userDidChange(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: AppDelegate.shared.authenticationController)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.messageWasSent(notification:)), name: NSNotification.Name.RedditMessageDidSend, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.objectsDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: AppDelegate.shared.managedObjectContext)
        
        // We can't trust ManualViewControllerInsets to adjust the table view insets, because the insets should be set before setting the UIRefreshControl and the parent view is not initialized before the refresh control is set. Let's use a static top offset of 44 then. Screw UIRefreshControl.
        self.tableView.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset
        
        self.collectionController.query = MessageCollectionQuery()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 60
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(MessagesViewController.refresh(_:)), for: .valueChanged)
        
        self.viewType = MessagesViewType.messages
    
        self.registerForPreviewing(with: self, sourceView: self.tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let objectContext: NSManagedObjectContext = AppDelegate.shared.managedObjectContext
        let unreadMessages = self.content?.filter({ (content) -> Bool in
            return (content as? Message)?.unread?.boolValue == true
        })
        if AppDelegate.shared.authenticationController.activeUser(objectContext)?.hasMail.boolValue == true && unreadMessages?.count == 0 {
            self.startCollectionControllerFetching(respectingExpirationDate: false)
        } else if self.collectionController.isCollectionExpired == true || self.content?.count == 0 {
            self.startCollectionControllerFetching(respectingExpirationDate: true)
        }
        self.tableView.reloadData()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Data
    
    @objc func refresh(_ sender: AnyObject?) {
        self.startCollectionControllerFetching()
    }
 
    // MARK: - Actions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == MessagesViewControllerShowMessageSegue {
            let conversationViewController = segue.destination as? MessageConversationViewController
            if let indexPath = self.tableView.indexPathForSelectedRow, let message = self.content?[indexPath.row] as? Message {
                conversationViewController?.message = message
                conversationViewController?.sentMessage = self.viewType == MessagesViewType.sent
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            return self.content?[indexPath.row] is Message && (self.viewType == .messages || self.viewType == .sent)
        }
        return true
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func userDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.content = nil
            _ = self.navigationController?.popToRootViewController(animated: false)
            self.startCollectionControllerFetching()
        }
    }
    
    @objc fileprivate func objectsDidChange(_ notification: Notification) {
        guard let deletedObjects: Set<NSManagedObject> = (notification as NSNotification).userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, let content: [Content] = self.content else {
            return
        }
        var objectInContentWasDeleted: Bool = false
        for object: NSManagedObject in deletedObjects {
            guard let contentItem: Content = object as? Content else {
                continue
            }
            if content.contains(contentItem) {
                objectInContentWasDeleted = true
                break
            }
        }
        if objectInContentWasDeleted {
            DispatchQueue.main.async {
                self.content = nil
                self.tableView.reloadData()
                self.startCollectionControllerFetching()
            }
        }
    }
    
    @objc fileprivate func messageWasSent(notification: Notification) {
        guard self.viewType == .sent else {
            return
        }
        DispatchQueue.main.async {
            self.startCollectionControllerFetching()
        }
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.emptyView?.layoutMargins = self.tableView.contentInset
    }
}

// MARK: - UITableViewDataSource
extension MessagesViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return min(self.content?.count ?? 0, 1)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.content?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = self.viewType == MessagesViewType.notifications ? "notification" : "message"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        if let messageCell = cell as? MessageCell {
            messageCell.sentMessage = self.viewType == MessagesViewType.sent
        }
        var messageCell = cell as! MessageObjectCell
        self.configureCell(&messageCell, atIndexPath: indexPath)
        return cell
    }
    
    fileprivate func configureCell(_ cell: inout MessageObjectCell, atIndexPath indexPath: IndexPath) {
        cell.message = self.content?[indexPath.row] as? Message
        cell.delegate = self
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let message = self.content?[indexPath.row] as? Message else {
            return
        }
        if self.viewType == .notifications {
            let referenceObject = message.reference
            if let referenceObject = referenceObject as? Comment {
                self.openCommentNotification(referenceObject)
            } else if let referenceObject = referenceObject as? Post {
                self.openPostNotification(referenceObject)
            }
        } else {
            self.openMessage(message)
        }
        
        self.markMessageAsRead(message)
        tableView.deselectRow(at: indexPath, animated: true)
        
        if self.splitViewController?.displayMode == .primaryOverlay {
            //Changing the display mode directly after showViewController will cause a weird layout animation
            //This is a hack, but needed unfortunatly, tested on iOS 9 and 10
            DispatchQueue.main.async {
                self.splitViewController?.toggleMasterView()
            }
        }
    
    }
    
    fileprivate func markMessageAsRead(_ message: Message) {
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
            self.tableView.reloadData()
        }
    }
    
    fileprivate func openMessage(_ message: Message) {
        if let messageViewController = self.storyboard?.instantiateViewController(withIdentifier: "messageConversation") as? MessageConversationViewController {
            messageViewController.message = message
            self.showDetailViewController(messageViewController, sender: nil)
        }
    }
    
    fileprivate func openCommentNotification(_ comment: Comment) {
        
        if let post = comment.post {
            let detailViewController = PostDetailViewController(post: post, contextSubreddit: nil)
            let commentsViewController = self.commentsViewControllerWithParentComment(comment)
            let navigationController = SubredditNavigationController(navigationBarClass: BeamNavigationBar.self, toolbarClass: nil)
            navigationController.viewControllers = [detailViewController, commentsViewController]
            self.present(navigationController, animated: true, completion: nil)
        } else {
            let commentsViewController = self.commentsViewControllerWithParentComment(comment)
            let navigationController = CommentsNavigationController(navigationBarClass: BeamNavigationBar.self, toolbarClass: nil)
            navigationController.viewControllers = [commentsViewController]
            self.present(navigationController, animated: true, completion: nil)
        }
        
    }
    
    fileprivate func commentsViewControllerWithParentComment(_ comment: Comment) -> CommentsViewController {
        let commentsViewController = UIStoryboard(name: "Comments", bundle: nil).instantiateViewController(withIdentifier: "comments") as! CommentsViewController
        let childQuery = CommentCollectionQuery()
        childQuery.post = comment.post
        if let parentComment = comment.parent as? Comment {
            childQuery.parentComment = parentComment
        } else {
            childQuery.parentComment = comment
        }
        
        commentsViewController.query = childQuery
        return commentsViewController
        
    }
    
    class func fetchComment(_ objectName: String, handler: @escaping ((_ comment: Comment?, _ error: Error?) -> Void)) {
        let collectionController = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        let query = InfoQuery(fullName: objectName)
        collectionController.query = query
        collectionController.startInitialFetching { (collectionID: NSManagedObjectID?, error: Error?) -> Void in
            DispatchQueue.main.async {
                if error != nil {
                    handler(nil, error)
                }
                if let collectionID = collectionController.collectionID, let collection = AppDelegate.shared.managedObjectContext.object(with: collectionID) as? ObjectCollection, let comment = collection.objects?.firstObject as? Comment {
                    handler(comment, nil)
                } else {
                    handler(nil, NSError.beamError(404, localizedDescription: "Comment '\(objectName)' not found"))
                }
            }
        }
    }
    
    fileprivate func openPostNotification(_ post: Post) {
        if let postName = post.objectName {
            let postViewController = PostDetailViewController(postName: postName, contextSubreddit: nil)
            self.navigationController?.show(postViewController, sender: self)
        }
        
    }
    
}

extension MessagesViewController: MessageObjectCellDelegate {

    func messageObjectCell(_ cell: MessageObjectCell, didTapUsernameOnMessage message: Message) {
        if let username = self.viewType == MessagesViewType.sent ? message.destination: message.author, username != "[deleted]" {
            let navigationController = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as! BeamColorizedNavigationController
            let profileViewController = navigationController.viewControllers.first as! ProfileViewController
            profileViewController.username = username
            self.present(navigationController, animated: true, completion: nil)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension MessagesViewController {
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.refreshControl?.isRefreshing != true else {
            return
        }
        
        if scrollView.contentOffset.y > scrollView.contentSize.height - 600 && self.collectionController.moreContentAvailable {
            self.collectionController.startFetchingMore({ [weak self] (collectionID: NSManagedObjectID?, error: Error?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self?.content = self?.contentWithCollectionID(self?.collectionController.collectionID)
                    
                    if let error = error as NSError? {
                        if error.code == NSURLErrorNotConnectedToInternet && error.domain == NSURLErrorDomain {
                            self?.presentErrorMessage(AWKLocalizedString("error-loading-posts-internet"))
                        } else {
                            self?.presentErrorMessage(AWKLocalizedString("error-loading-posts"))
                        }
                    }
                })
                })
            self.loadingFooterView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.tableView.bounds.width, height: 100))
            self.tableView.tableFooterView = self.loadingFooterView
            self.loadingFooterView.startAnimating()
        }
    }
}

@available(iOS 9, *)
extension MessagesViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = self.tableView.indexPathForRow(at: location),
            let cell = self.tableView.cellForRow(at: indexPath),
            let messageConverstation = self.storyboard?.instantiateViewController(withIdentifier: "messageConversation") as? MessageConversationViewController,
            let message = self.content?[indexPath.row] as? Message,
            self.viewType == .messages || self.viewType == .sent {
            
                //Make viewcontroller
                messageConverstation.message = message
            
                //Set the frame to animate the peek from
                previewingContext.sourceRect = cell.frame
            
                //Pass the view controller to display
                return messageConverstation
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.show(viewControllerToCommit, sender: previewingContext)
    }
}
