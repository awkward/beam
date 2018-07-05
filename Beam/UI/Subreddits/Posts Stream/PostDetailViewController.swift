//
//  PostDetailViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 02-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData
import AWKGallery
import TTTAttributedLabel
import CherryKit
import SafariServices
import Trekker

/// This class is the detail view controller of a post. The actual view is embedded in this view. See PostDetailEmbeddedViewController below.
/// PostDetailViewController makes use of a embedded view controller because a UITableViewController is required to get a UIRefreshControl and StreamViewController (which PostDetailEmbeddedViewController is) is already a UITableViewController.
/// However, the skip thread button needs to float on top of the UITableView. Therefore this button is added to a UIViewController together with the embedded view controller.
class PostDetailViewController: BeamViewController, CommentThreadSkipping {
    
    var tableView: UITableView? {
        return self.embeddedViewController.tableView
    }
    
    var scrollToCommentsOnLoad: Bool {
        set {
            self.embeddedViewController.scrollToCommentsOnLoad = newValue
        }
        get {
            return self.embeddedViewController.scrollToCommentsOnLoad
        }
    }
    
    lazy var skipThreadButton: UIButton = {
        let button = UIButton()
        button.alpha = 0.8
        button.addTarget(self, action: #selector(PostDetailViewController.skipThreadTapped(sender:)), for: UIControlEvents.touchUpInside)
        return button
    }()
    
    var embeddedViewController: PostDetailEmbeddedViewController!
    
    fileprivate var previousFrame: CGRect?
    
    init(postName: String, contextSubreddit: Subreddit?) {
        self.embeddedViewController = PostDetailEmbeddedViewController(postName: postName, contextSubreddit: contextSubreddit)
        super.init(nibName: nil, bundle: nil)
    }
    
    init(post: Post, contextSubreddit: Subreddit?) {
        self.embeddedViewController = PostDetailEmbeddedViewController(post: post, contextSubreddit: contextSubreddit)
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupView() {
        self.embeddedViewController.view.frame = self.view.bounds
        self.embeddedViewController.willMove(toParentViewController: self)
        self.addChildViewController(self.embeddedViewController)
        self.view.addSubview(self.embeddedViewController.view)
        self.embeddedViewController.didMove(toParentViewController: self)
        
        self.embeddedViewController.tableView.expandScrollArea()
        
        self.embeddedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        //Add horizontal constraints to make the view center with a max width
        self.view.addConstraint(NSLayoutConstraint(item: self.embeddedViewController.view, attribute: .leading, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: self.embeddedViewController.view, attribute: .trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.embeddedViewController.view, attribute: .centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0))
        self.embeddedViewController.view.addConstraint(NSLayoutConstraint(item: self.embeddedViewController.view, attribute: .width, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIView.MaximumViewportWidth))
        
        //Limit the actual width, but give it a lower priority (750) so that it can be smaller if it needs to be (on iPhone for example)
        let widthConstraint = NSLayoutConstraint(item: self.embeddedViewController.view, attribute: .width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: UIView.MaximumViewportWidth)
        widthConstraint.priority = UILayoutPriority.defaultHigh
        self.embeddedViewController.view.addConstraint(widthConstraint)
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[viewController]|", options: [], metrics: nil, views: ["viewController": self.embeddedViewController.view]))
        
        //Add the skip thread button
        self.skipThreadButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.skipThreadButton)
        self.view.trailingAnchor.constraint(equalTo: self.skipThreadButton.trailingAnchor, constant: 12).isActive = true
        self.view.bottomAnchor.constraint(equalTo: self.skipThreadButton.bottomAnchor, constant: 12).isActive = true
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "compose_icon"), style: UIBarButtonItemStyle.plain, target: self.embeddedViewController, action: #selector(PostDetailEmbeddedViewController.composeTapped(_:)))
    
        //Disable the scrollbar on iPad, it looks weird
        if let tableView = self.tableView, UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            tableView.showsVerticalScrollIndicator = false
        }
        
        //Make sure the skip thread button is on top of everything
        self.view.bringSubview(toFront: self.skipThreadButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isModallyPresentedRootViewController() == true {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_close"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(UIViewController.dismissViewController(_:)))
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get {
            return true
        }
        set {
            //Do nothing
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.skipThreadButton.setImage(DisplayModeValue(UIImage(named: "next_button_icon"), darkValue: UIImage(named: "next_button_icon_dark")), for: UIControlState())
    }
    
    @objc fileprivate func skipThreadTapped(sender: UIButton) {
        self.scrollToNextCommentThread()
    }
}

/// This is the view controller that is embedded in the PostDetailViewController. It is a subclass of StreamViewController because the first section uses the same logic as StreamViewController
class PostDetailEmbeddedViewController: StreamViewController {
    
    let commentsDataSource = CommentsDataSource()
    
    lazy var commentsHeaderView: CommentsHeaderView = {
        return CommentsHeaderView.headerView(withDelegate: self)
    }()
    
    lazy var commentsFooterView: CommentsFooterView = {
        return CommentsFooterView.footerView()
    }()
    
    var scrollToCommentsOnLoad: Bool = false
    
    // Context Subreddit is set to the subreddit the user is currently viewing, this can for instance be the frontpage. The context subreddit is the subreddit the user came from like the frontpage or a specific subreddit. It is used for detemening the NSFW/Spoiler overlay and if the subreddit should be shown or not
    weak var contextSubreddit: Subreddit?
    
    override var visibleSubreddit: Subreddit? {
        return self.contextSubreddit
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get {
            return true
        }
        set {
            //Do nothing
        }
    }
    
    override var content: [Content]? {
        didSet {
            if let post = self.content?.first as? Post {
                self.setupCommentsQuery(post)
                self.fetchComments()
            }
        }
    }
    
    init(postName: String, contextSubreddit: Subreddit?) {
        super.init(style: UITableViewStyle.grouped)
        self.contextSubreddit = contextSubreddit
        self.query = ObjectNamesQuery(fullNames: [postName])
        self.startCollectionControllerFetching()
    }
    
    init(post: Post, contextSubreddit: Subreddit?) {
        super.init(style: UITableViewStyle.grouped)
        self.contextSubreddit = contextSubreddit
        self.query = ObjectNamesQuery(fullNames: [post.objectName!])
        if self.postRequiresFetching(post: post) {
            self.startCollectionControllerFetching()
        } else {
            self.startsFetchingOnViewWillAppear = false
            self.content = [post]
        }
        self.setupCommentsQuery(post)
        self.fetchComments()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func postRequiresFetching(post: Post?) -> Bool {
        guard let post = post, post.title != nil && post.author != nil && ((post.isSelfText.boolValue == true && post.content != nil) || (post.isSelfText.boolValue == false && post.urlString != nil)) && post.permalink != nil else {
            //The post doesn't exist, fetch it ofcourse!
            return true
        }
        return false
    }
    
    override func refreshContent(_ sender: AnyObject?) {
        //Do nothing but refresh the comments!
        self.fetchComments()
    }
    
    fileprivate func setupCommentsQuery(_ post: Post) {
        self.commentsDataSource.query.sortType = post.subreddit?.commentsSortType ?? .best
        self.commentsDataSource.query.post = post
        self.commentsHeaderView.sortType = self.commentsDataSource.query.sortType
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.commentsDataSource.indexPathSectionOffset = 1
        self.commentsDataSource.registerCells(self.tableView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PostDetailEmbeddedViewController.postDidChangeSavedState(_:)), name: .ContentDidChangeSavedState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PostDetailEmbeddedViewController.commentPosted(_:)), name: .CommentPosted, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.presentedViewController == nil {
            self.commentsDataSource.createThreads()
        }
    }
    
    @objc fileprivate func composeTapped(_ sender: AnyObject) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.General), animated: true, completion: nil)
            return
        }
        
        guard self.commentsDataSource.query.post?.locked.boolValue == false && self.commentsDataSource.query.post?.archived.boolValue == false else {
            if self.commentsDataSource.query.post?.locked.boolValue == true {
                self.presentErrorMessage(AWKLocalizedString("locked-error-message"))
            } else {
                self.presentErrorMessage(AWKLocalizedString("archived-error-message"))
            }
            return
        }
        
        let storyBoard = UIStoryboard(name: "Comments", bundle: nil)
        let navigationController = storyBoard.instantiateViewController(withIdentifier: "compose") as! CommentsNavigationController
        navigationController.useInteractiveDismissal = false
        let composeViewController = navigationController.topViewController as! CommentComposeViewController
        composeViewController.post = self.commentsDataSource.query.post
        self.present(navigationController, animated: true, completion: nil)
    }
    
    fileprivate func fetchComments() {
        if self.commentsDataSource.status == .fetching {
            self.reloadCommentsLoadingState()
            return
        }
        self.commentsDataSource.fetchComments { (_, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if error != nil {
                    self.presentErrorMessage(AWKLocalizedString("error-loading-comments"))
                }
                self.tableView.reloadData()
                if self.refreshControl?.isRefreshing == true {
                    self.refreshControl?.endRefreshing()
                }
                self.reloadCommentsLoadingState()
                if self.numberOfSections(in: self.tableView) > 1 && self.tableView(self.tableView, numberOfRowsInSection: 1) > 0 {
                    if self.scrollToCommentsOnLoad == true {
                        self.scrollToCommentsOnLoad = false
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: UITableViewScrollPosition.top, animated: true)
                    }
                }
            })
        }
        self.reloadCommentsLoadingState()
    }
    
    fileprivate func reloadCommentsLoadingState() {
        var view: CommentsFooterView? = nil
        
        let isFetching: Bool = self.commentsDataSource.status == .fetching
        
        if let content: [Content] = self.content, let threads: [[Comment]] = self.commentsDataSource.threads {
            if threads.count == 0 && content.count > 0 && isFetching == true {
                self.commentsFooterView.state = CommentsFooterViewState.loading
                let height: CGFloat = self.view.frame.height - self.commentsHeaderView.frame.height - self.topLayoutGuide.length
                self.commentsFooterView.height = height
                view = self.commentsFooterView
            }
            
            if threads.count == 0 && content.count > 0 && isFetching == false {
                self.commentsFooterView.state = CommentsFooterViewState.empty
                self.commentsFooterView.height = nil
                view = self.commentsFooterView
            }
        }
        
        self.tableView.tableFooterView = nil
        if let view = view {
            let width: CGFloat = self.view.bounds.width
            view.sizeToFitWidth(width)
            self.tableView.tableFooterView = view
        }
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func commentPosted(_ notification: Notification) {
        DispatchQueue.main.async {
            if let comment = notification.object as? Comment, let indexPath = self.commentsDataSource.insertComment(comment) {
                let createNewSection = indexPath.section >= self.tableView.numberOfSections
                self.tableView.beginUpdates()
                if createNewSection {
                    self.tableView.insertSections(IndexSet(integer: indexPath.section), with: .automatic)
                } else {
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                }
                self.tableView.endUpdates()
            } else {
                self.commentsDataSource.threads = nil
                self.tableView.reloadData()
                self.fetchComments()
            }
        }
        
    }
    
    override func contentDidDelete(_ notification: Notification) {
        super.contentDidDelete(notification)
        DispatchQueue.main.async { () -> Void in
            if let comment: Comment = notification.object as? Comment {
                guard let indexPath = self.commentsDataSource.indexPath(forComment: comment), let configureIndexPath = self.commentsDataSource.indexPath(forComment: comment, withOffset: false), let cell = self.tableView.cellForRow(at: indexPath) as? BaseCommentCell else {
                    return
                }
                self.tableView.beginUpdates()
                self.commentsDataSource.configureCell(cell, indexPath: configureIndexPath)
                print("Update cell at index \(indexPath)")
                self.tableView.endUpdates()
            }
        }
    }
    
    override func postDidChangeSavedState(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            if let post = notification.object as? Post, post.isSaved.boolValue == true && self.content?.contains(post) == true {
                self.presentSuccessMessage(AWKLocalizedString("post-saved-succesfully"))
            } else if let comment = notification.object as? Comment, comment.isSaved.boolValue == true {
                self.presentSuccessMessage(AWKLocalizedString("comment-saved-succesfully"))
            }
        }
    }
    
    override func postDidChangeHiddenFlag(_ notification: Notification) {
        //We want custom behavior if the currently displayed post is hidden. In the case the current post is hidden, we just want to close the view. Calling super could cause a crash because it wants to reload a post that no longer exists
        if let content = self.content, let post = notification.object as? Post, content.contains(post) == true {
            _ = self.navigationController?.popViewController(animated: true)
        } else {
            super.postDidChangeHiddenFlag(notification)
        }
    }
    
    //Translates the indexPath to one for the comments. This just makes the section start at 0
    func commentIndexPath(_ indexPath: IndexPath) -> IndexPath {
        return IndexPath(row: (indexPath as IndexPath).row, section: (indexPath as IndexPath).section - 1)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let content = self.content, content.count > 0 {
            //Add comments count
            let threadCount: Int = (self.commentsDataSource.threads?.count ?? 0)
            return 1 + max(threadCount, 1)
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return super.tableView(tableView, numberOfRowsInSection: section)
        } else {
            //Comments count
            return self.commentsDataSource.commentsAtIndex(section - 1)?.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as IndexPath).section == 0 {
            return super.tableView(tableView, cellForRowAt: indexPath)
        } else {
            if let cell = self.commentsDataSource.commentCell(forTableView: tableView, atIndexPath: indexPath) {
                if let commentCell = cell as? CommentCell {
                    commentCell.contentLabel.delegate = self
                    commentCell.delegate = self
                }
                return cell
            } else {
                //This is an edge case to safe from crashing
                return tableView.dequeueReusableCell(withIdentifier: "continue_thread", for: indexPath)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as IndexPath).section == 0 {
            return super.tableView(tableView, heightForRowAt: indexPath)
        } else if let comment = self.commentsDataSource.commentAtIndexPath(self.commentIndexPath(indexPath)) {
            return self.commentsDataSource.commentCellHeightForComment(comment)
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as IndexPath).section == 0 {
            return super.tableView(tableView, estimatedHeightForRowAt: indexPath)
        } else if let comment = self.commentsDataSource.commentAtIndexPath(self.commentIndexPath(indexPath)) {
            return self.commentsDataSource.commentCellHeightForComment(comment)
        }
        return 60
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            return self.commentsHeaderView
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return ThumbnailsViewType.large.headerSpacingHeight(atIndex: section)
        } else if section == 1 {
            return self.commentsHeaderView.detailViewHeight
        } else {
            return 4
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return ThumbnailsViewType.large.footerSpacingHeight(atIndex: section)
        } else {
            if section == tableView.numberOfSections - 1 {
                return 8
            }
            return 4
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        if let commentCell = cell as? CommentCell {
            commentCell.resetScrollViewOffset()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as IndexPath).section == 0 {
            super.tableView(tableView, didSelectRowAt: indexPath)
        } else {
            let newIndexPath = self.commentIndexPath(indexPath)
            if let comment = self.commentsDataSource.commentAtIndexPath(newIndexPath) {
                if self.commentsDataSource.isCommentOutsideOfDepthLimit(comment) {
                    let storyboard = UIStoryboard(name: "Comments", bundle: nil)
                    let viewController = storyboard.instantiateViewController(withIdentifier: "comments") as! CommentsViewController
                    let childQuery = CommentCollectionQuery()
                    childQuery.parentComment = self.commentsDataSource.commentAtIndexPath(IndexPath(row: newIndexPath.row - 1, section: indexPath.section - 1))
                    childQuery.post = self.commentsDataSource.query.post
                    childQuery.sortType = self.commentsDataSource.query.sortType
                    viewController.query = childQuery
                    
                    self.navigationController?.pushViewController(viewController, animated: true)
                } else if comment is MoreComment {
                    UIApplication.startNetworkActivityIndicator(for: self)
                    self.commentsDataSource.loadMoreCommentChildren(comment as! MoreComment, completionHandler: { (error) -> Void in
                        DispatchQueue.main.async {
                            if let error = error as NSError? {
                                if error.code == -20 && error.domain == BeamErrorDomain {
                                    self.present( BeamAlertController(alertWithCloseButtonAndTitle: AWKLocalizedString("not-possible"), message: AWKLocalizedString("load-more-comments-not-possible")), animated: true, completion: nil)
                                } else {
                                    self.presentErrorMessage(AWKLocalizedString("error-loading-more-comments"))
                                    AWKDebugLog("Error loading more comments: \(error)")
                                }
                            }
                            
                            self.tableView.reloadData()
                        }
                        UIApplication.stopNetworkActivityIndicator(for: self)
                    })
                    if let cell = tableView.cellForRow(at: indexPath) as? LoadMoreCommentsCell {
                        cell.loading = true
                        cell.reloadContents()
                    }
                }
                //NOTE: didSelectRowAtIndexPath does not work for "CommentCell", please see the CommentCellDelegate instead
            }
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        if scrollView.isDragging {
            self.scrollToCommentsOnLoad = false
        }
    }
    
}

extension PostDetailEmbeddedViewController: CommentsHeaderViewDelegate {
    
    func commentsHeaderView(_ headerView: CommentsHeaderView, didChangeSortType sortType: CollectionSortType) {
        self.commentsDataSource.query.sortType = sortType
        self.commentsDataSource.threads = nil
        self.commentsDataSource.query.post?.subreddit?.commentsSortType = sortType
        self.fetchComments()
        self.tableView.reloadData()
    }
    
}

extension PostDetailEmbeddedViewController: CommentCellDelegate {

    func commentsDataSource(for cell: CommentCell) -> CommentsDataSource {
        return self.commentsDataSource
    }
    
    func commentCell(_ cell: CommentCell, didProduceErrorMessage message: String) {
        self.presentErrorMessage(message)
    }
    
    func commentCell(_ cell: CommentCell, didTapImagePreview comment: Comment, mediaObjects: [MediaObject]) {
        self.presentGallery(with: mediaObjects)
    }
    
}
