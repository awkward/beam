//
//  CommentsViewController.swift
//  beam
//
//  Created by Robin Speijer on 31-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData
import TTTAttributedLabel
import Trekker
import AWKGallery

/// This is the class to only display comments or display a single comment thread.
/// This view embeds a view controller so a button can be added on top of the UITableViewController.
/// UITableViewController is used because a refresh control is needed on iOS 9.
class CommentsViewController: BeamViewController, CommentThreadSkipping {

    var tableView: UITableView? {
        return embeddedViewController.tableView
    }
    
    lazy var skipThreadButton: UIButton = {
        let button = UIButton()
        button.alpha = 0.8
        button.addTarget(self, action: #selector(CommentsViewController.skipThreadTapped(sender:)), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    fileprivate var embeddedViewController = CommentsEmbeddedViewController(style: .grouped)
    
    var post: Post? {
        get {
            return self.embeddedViewController.post
        }
        set {
            self.embeddedViewController.post = newValue
        }
    }
    
    var query: CommentCollectionQuery {
        get {
            return self.embeddedViewController.query
        }
        set {
            self.embeddedViewController.query = newValue
        }
    }
    
    /// The parent comment. If set, the view will only display this parent comment and it's replies
    var parentComment: Comment? {
        get {
            return self.embeddedViewController.parentComment
        }
        set {
            self.embeddedViewController.parentComment = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView?.backgroundColor = AppearanceValue(light: .systemGroupedBackground, dark: .beamDarkBackground)
        tableView?.separatorColor = .beamTableViewSeperator
        
        self.hidesBottomBarWhenPushed = true
        
        if self.parentComment == nil {
            self.navigationItem.title = AWKLocalizedString("comments-title")
        } else {
            self.navigationItem.title = AWKLocalizedString("thread-title")
        }
        
        if self.parentComment == nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "compose_icon"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(CommentsViewController.composeTapped(_:)))
        }
        
        self.addChild(self.embeddedViewController)
        self.view.addSubview(self.embeddedViewController.view)
        self.embeddedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": self.embeddedViewController.view!]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view": self.embeddedViewController.view!]))
        self.embeddedViewController.didMove(toParent: self)
        
        //Add the skip thread button, but only if we aren't looking at a parent comment
        if self.parentComment == nil {
            //Add the skip thread button
            self.skipThreadButton.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.skipThreadButton)
            self.view.bringSubviewToFront(self.skipThreadButton)
            self.view.trailingAnchor.constraint(equalTo: self.skipThreadButton.trailingAnchor, constant: 12).isActive = true
            self.view.bottomAnchor.constraint(equalTo: self.skipThreadButton.bottomAnchor, constant: 12).isActive = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //The navigationController might not be set earlier than viewWillAppear(:), so we update the item here
        if self.isModallyPresentedRootViewController() {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(CommentsViewController.doneButtonTapped(_:)))
        }
    }
    
    // MARK: - Actions
    
    @objc fileprivate func doneButtonTapped(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func composeTapped(_ sender: AnyObject) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.General), animated: true, completion: nil)
            return
        }
        
        guard self.query.post?.locked.boolValue == false && self.query.post?.archived.boolValue == false else {
            if self.query.post?.locked.boolValue == true {
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
        composeViewController.post = self.query.post
        self.present(navigationController, animated: true, completion: nil)
    }
    override func appearanceDidChange() {
        super.appearanceDidChange()
        self.skipThreadButton.setImage(AppearanceValue(light: UIImage(named: "next_button_icon"), dark: UIImage(named: "next_button_icon_dark")), for: UIControl.State())
    }

    @objc fileprivate func skipThreadTapped(sender: UIButton) {
        self.scrollToNextCommentThread()
    }

}

/// The view controller that displays the actual comments and is embbeded in CommentsViewController
private class CommentsEmbeddedViewController: BeamTableViewController, MediaObjectsGalleryPresentation {
    
    // MARK: - Data Source
    fileprivate var dataSource = CommentsDataSource()
    
    var galleryMediaObjects: [MediaObject]?
    
    lazy var headerView: CommentsHeaderView = {
        return CommentsHeaderView.headerView(withDelegate: self)
    }()
    lazy var footerView: CommentsFooterView = {
        return CommentsFooterView.footerView()
    }()
    
    var post: Post? {
        get {
            return self.dataSource.query.post
        }
        set {
            self.dataSource.query.post = newValue
        }
    }
    
    var query: CommentCollectionQuery {
        get {
            return self.dataSource.query
        }
        set {
            self.dataSource.query = newValue
        }
    }
    
    var parentComment: Comment? {
        get {
            return self.dataSource.query.parentComment
        }
        set {
            self.dataSource.query.parentComment = newValue
        }
    }
    
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource.registerCells(self.tableView)
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 60
        self.tableView.separatorStyle = .none
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(CommentsEmbeddedViewController.refresh(_:)), for: .valueChanged)
        
        self.fetchComments()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsEmbeddedViewController.contentDidDelete(_:)), name: .ContentDidDelete, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    // MARK: - Data
    
    @objc fileprivate func contentDidDelete(_ notification: Notification) {
        if let comment: Comment = notification.object as? Comment {
            guard let indexPath = self.dataSource.indexPath(forComment: comment), let configureIndexPath = self.dataSource.indexPath(forComment: comment, withOffset: false), let cell = self.tableView.cellForRow(at: indexPath) as? BaseCommentCell else {
                return
            }
            self.tableView.beginUpdates()
            self.dataSource.configureCell(cell, indexPath: configureIndexPath)
            self.tableView.endUpdates()
        }
    }
    
    @objc func refresh(_ sender: AnyObject?) {
        self.fetchComments()
    }
    
    fileprivate func fetchComments() {
        if self.dataSource.status == .fetching {
            self.reloadLoadingState()
            return
        }
        self.dataSource.fetchComments { (_, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if error != nil {
                    self.presentErrorMessage(AWKLocalizedString("error-loading-comments"))
                }
                self.tableView.reloadData()
                if self.refreshControl?.isRefreshing == true {
                    self.refreshControl?.endRefreshing()
                }
                self.reloadLoadingState()
            })
        }
        self.reloadLoadingState()
    }
    
    func reloadLoadingState() {
        var view: CommentsFooterView?
        
        let isFetching: Bool = self.dataSource.status == .fetching
        
        if let threads: [[Comment]] = self.dataSource.threads {
            if threads.count == 0 && isFetching == true {
                self.footerView.state = CommentsFooterViewState.loading
                let height: CGFloat = self.view.frame.height - self.view.safeAreaInsets.top
                self.footerView.height = height
                view = self.footerView
            }
            
            if threads.count == 0 && isFetching == false {
                self.footerView.state = CommentsFooterViewState.empty
                self.footerView.height = nil
                view = self.footerView
            }
        }
        
        self.tableView.tableFooterView = nil
        if let view = view {
            let width: CGFloat = self.view.bounds.width
            view.sizeToFitWidth(width)
            self.tableView.tableFooterView = view
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return max(self.dataSource.threads?.count ?? 0, 1)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.commentsAtIndex(section)?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.dataSource.commentCell(forTableView: tableView, atIndexPath: indexPath) {
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
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == tableView.numberOfSections - 1 {
            return 8
        }
        return 4
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if self.parentComment == nil {
                return self.headerView.commentsViewHeight
            } else {
                return 8
            }
        }
        return 4
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 && self.parentComment == nil {
            return self.headerView
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let comment = self.dataSource.commentAtIndexPath(indexPath) {
            return self.dataSource.commentCellHeightForComment(comment)
        }
        return UITableView.automaticDimension
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let commentCell = cell as? CommentCell {
            commentCell.resetScrollViewOffset()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let commentsStoryboard = UIStoryboard(name: "Comments", bundle: nil)
        if let comment = self.dataSource.commentAtIndexPath(indexPath) {
            if self.dataSource.isCommentOutsideOfDepthLimit(comment), let viewController = commentsStoryboard.instantiateViewController(withIdentifier: "comments") as? CommentsViewController {
                let childQuery = CommentCollectionQuery()
                childQuery.parentComment = self.dataSource.commentAtIndexPath(IndexPath(row: indexPath.row - 1, section: indexPath.section))
                childQuery.post = self.query.post
                childQuery.sortType = self.query.sortType
                viewController.query = childQuery
                
                self.navigationController?.pushViewController(viewController, animated: true)
            } else if comment is MoreComment {
                self.dataSource.loadMoreCommentChildren(comment as! MoreComment, completionHandler: { (error) -> Void in
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
                })
                self.tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            }
            //NOTE: didSelectRowAtIndexPath does not work for "CommentCell", please see the CommentCellDelegate instead
        }
    }
    
}

extension CommentsEmbeddedViewController: CommentsHeaderViewDelegate {
    
    func commentsHeaderView(_ headerView: CommentsHeaderView, didChangeSortType sortType: CollectionSortType) {
        self.dataSource.query.sortType = sortType
        self.dataSource.threads = nil
        self.fetchComments()
        self.tableView.reloadData()
    }
    
}

extension CommentsEmbeddedViewController: TTTAttributedLabelDelegate {
    
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

//MARL: - AWKGalleryDataSource

extension CommentsEmbeddedViewController: AWKGalleryDataSource {
    
    // MARK: - AWKGalleryDataSource
    
    func numberOfItems(inGallery galleryViewController: AWKGalleryViewController) -> Int {
        guard let mediaObjects = self.galleryMediaObjects else {
            return 0
        }
        return mediaObjects.count
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, itemAt index: UInt) -> AWKGalleryItem {
        if let mediaObject = self.galleryMediaObjects?[Int(index)] {
            return mediaObject.galleryItem
        } else {
            fatalError()
        }
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, indexOf item: AWKGalleryItem) -> Int {
        return (self.galleryMediaObjects?.firstIndex(where: { (mediaObject: MediaObject) -> Bool in
            return mediaObject.contentURL == item.contentURL
        })) ?? 0
    }
    
}

// MARK: - AWKGalleryDelegate

extension CommentsEmbeddedViewController: AWKGalleryDelegate {
    
    func gallery(_ galleryViewController: AWKGalleryViewController, presentationAnimationSourceViewFor item: AWKGalleryItem) -> UIView? {
        return nil
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, shouldBeDismissedAnimated animated: Bool) {
        self.dismissGalleryViewController(galleryViewController, sourceView: nil)
    }
    
}

extension CommentsEmbeddedViewController: CommentCellDelegate {
    
    func commentsDataSource(for cell: CommentCell) -> CommentsDataSource {
        return self.dataSource
    }
    
    func commentCell(_ cell: CommentCell, didProduceErrorMessage message: String) {
        self.presentErrorMessage(message)
    }
    
    func commentCell(_ cell: CommentCell, didTapImagePreview comment: Comment, mediaObjects: [MediaObject]) {
        self.presentGallery(with: mediaObjects)
    }
    
}
