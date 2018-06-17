//
//  CommentComposeViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 29-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import Trekker

class CommentComposeViewController: BeamViewController {
    
    fileprivate var previousViewBounds = CGRect()
    fileprivate var keyboardFrame = CGRect()
    
    @IBOutlet fileprivate var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var textView: UITextView!
    @IBOutlet fileprivate var tableView: UITableView!
    @IBOutlet fileprivate var replyLabel: UILabel!
    
    //The comment when you are editing a comment
    var comment: Comment? {
        didSet {
            if self.isViewLoaded {
                self.updateViewContent()
            }
        }
    }
    
    var editCommentActivity: EditCommentActivity?
    
    //The post when making a new comment, also required when parentComment is set
    var post: Post? {
        didSet {
            if self.isViewLoaded {
                self.updateViewContent()
            }
        }
    }
    
    //The comment when replying to a comment
    var parentComment: Comment? {
        didSet {
            if self.isViewLoaded {
                self.updateViewContent()
            }
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(CommentComposeViewController.keyboardFrameWillChange(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        //Configure the tableView
        self.tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "comment")
        self.tableView.register(UINib(nibName: "PostTitleWithThumbnailPartCell", bundle: nil), forCellReuseIdentifier: "titlethumbnail")
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        //Configure the textView
        self.textView.textContainerInset = UIEdgeInsets.zero
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.isScrollEnabled = false
        
        //Configure data on the view that can be variable
        self.updateViewContent()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textView.becomeFirstResponder()
    }
    
    /// Updates content of the view such as the navigation title, navigation items and it's "content views" such as the text view
    fileprivate func updateViewContent() {
        if self.comment != nil {
            self.title = NSLocalizedString("edit-comment-view-title", comment: "The view title of a edit comment view")
        } else {
            self.title = NSLocalizedString("new-comment-view-title", comment: "The view title of a new comment view")
        }
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: AWKLocalizedString("cancel-button"), style: .plain, target: self, action: #selector(CommentComposeViewController.close(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.comment != nil ? AWKLocalizedString("save-button") : AWKLocalizedString("post-button"), style: .done, target: self, action: #selector(CommentComposeViewController.post(_:)))
        
        self.textView.text = self.comment?.content
        
        self.updateReplyLabel()
        
    }
    
    /// Updates the reply to label on the view with a attributed string
    fileprivate func updateReplyLabel() {
        var username: String?
        if let comment = self.parentComment {
            username = comment.author
        } else if let post = self.post {
            username = post.author
        }
        
        let labelText = NSLocalizedString("in-reply-to-compose-comment-label", comment: "The \"In reply to\" label on the comment compose view, followed by the user's username")
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        let font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.semibold)
        var attributedText: NSMutableAttributedString = NSMutableAttributedString(string: labelText, attributes: [NSAttributedStringKey.foregroundColor: textColor.withAlphaComponent(0.5), NSAttributedStringKey.font: font])
        if let username = username {
            let usernameAttributedString = NSAttributedString(string: " \(username)", attributes: [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.font: font])
            attributedText.append(usernameAttributedString)
        } else {
            attributedText = NSMutableAttributedString(string: NSLocalizedString("reply-compose-comment-label", comment: "A simple reply label"), attributes: [NSAttributedStringKey.foregroundColor: textColor.withAlphaComponent(0.5), NSAttributedStringKey.font: font])
        }
        self.replyLabel.attributedText = attributedText
    }
    
    // MARK: - Display Mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        self.view.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.textView.superview?.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.textView.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.textView.textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.textView.keyboardAppearance = DisplayModeValue(UIKeyboardAppearance.default, darkValue: UIKeyboardAppearance.dark)
        self.textView.tintColor = DisplayModeValue(UIColor.beamPurple(), darkValue: UIColor.beamPurpleLight())
        
        self.updateReplyLabel()
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func keyboardFrameWillChange(_ notification: Notification) {
        let endFrame = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        self.keyboardFrame = endFrame
        self.updateInset()
    }
    
    // MARK: - Actions
    
    @objc fileprivate func close(_ sender: UIBarButtonItem) {
        self.textView.resignFirstResponder()
        if let text = self.textView?.text, text.count > 0 {
            let alertController = BeamAlertController(title: nil, message: AWKLocalizedString("are-you-sure-discard-comment"), preferredStyle: UIAlertControllerStyle.actionSheet)
            alertController.addAction(UIAlertAction(title: AWKLocalizedString("discard-comment"), style: UIAlertActionStyle.destructive, handler: { (_) -> Void in
                self.dismissView()
            }))
            alertController.addCancelAction()
            
            alertController.popoverPresentationController?.barButtonItem = sender
            
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.dismissView()
        }
    }
    
    fileprivate func dismissView() {
        if let activity = self.editCommentActivity {
            activity.activityDidFinish(true)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func post(_ sender: AnyObject) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.Comment), animated: true, completion: nil)
            return
        }
        
        guard let text = self.textView?.text, text.count > 0 else {
            let message = AWKLocalizedString("comment-too-short-message")
            let title = AWKLocalizedString("comment-too-short")
            let alertController = BeamAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            alertController.addCloseAction()
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        BeamSoundType.tap.play()
        
        if self.comment != nil {
            self.updateComment()
        } else if let comment = self.parentComment {
            self.replyToComment(comment)
        } else if let post = self.post {
            self.replyToPost(post)
        }
    }
    
    // MARK: - Data actions
    
    fileprivate func updateComment() {
        guard let text = self.textView.text, let comment = self.comment else {
            return
        }
        do {
            let operations = try comment.updateOperations(text, authenticationcontroller: AppDelegate.shared.authenticationController)
            self.comment!.content = text
            self.comment!.markdownString = nil
            self.executeOperations(operations)
        } catch let error as NSError {
            let alertView = BeamAlertController(title: AWKLocalizedString("could-not-update-comment"), message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
            alertView.addCancelAction()
            self.present(alertView, animated: true, completion: nil)
        }
        
    }
    
    fileprivate func replyToComment(_ comment: Comment) {
        guard let text = self.textView.text else {
            return
        }
        let operations = comment.replyOperations(text, authenticationcontroller: AppDelegate.shared.authenticationController)
        self.executeOperations(operations)
    }
    
    fileprivate func replyToPost(_ post: Post) {
        guard let text = self.textView.text else {
            return
        }
        let operations = post.replyOperations(text, authenticationcontroller: AppDelegate.shared.authenticationController)
        self.executeOperations(operations)
    }
    
    fileprivate func executeOperations(_ operations: [Operation]) {
        UIApplication.startNetworkActivityIndicator(for: self)
        self.textView?.isSelectable = false
        self.textView?.resignFirstResponder()
        DataController.shared.executeAndSaveOperations(operations, context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
            DispatchQueue.main.async {
                if let error = error {
                    if self.comment != nil {
                        let alertView = BeamAlertController(title: AWKLocalizedString("could-not-update-comment"), message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                        alertView.addCancelAction()
                        self.present(alertView, animated: true, completion: nil)
                    } else {
                        let alertView = BeamAlertController(title: AWKLocalizedString("could-not-post-comment"), message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                        alertView.addCancelAction()
                        self.present(alertView, animated: true, completion: nil)
                    }
                    self.textView?.isSelectable = true
                } else {
                    let thingsOperation = operations.compactMap({ (operation) -> ThingsParsingOperation? in
                        return operation as? ThingsParsingOperation
                    }).first
                    
                    if self.comment == nil {
                        Trekker.default.track(event: "Post comment")
                        
                        if let postedComment = thingsOperation?.things?.first as? Comment {
                            NotificationCenter.default.post(name: .CommentPosted, object: postedComment)
                        } else {
                            NotificationCenter.default.post(name: .CommentPosted, object: nil)
                        }
                        
                    } else {
                        Trekker.default.track(event: "Update comment")
                        NotificationCenter.default.post(name: .CommentUpdated, object: nil)

                    }
                    self.finishedExecuting()
                    
                }
            }
            
            UIApplication.stopNetworkActivityIndicator(for: self)
        })
    }
    
    fileprivate func finishedExecuting() {
        self.dismissView()
    }
    
    // MARK: - Layout

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.sizeTableView()
        
        if self.view.bounds.size != self.previousViewBounds.size {
            self.updateInset()
        }
        
        self.previousViewBounds = self.view.bounds
    }
    
    fileprivate func sizeTableView() {
        let rowRect: CGRect = self.tableView.rectForRow(at: IndexPath(row: 0, section: 0))
        if rowRect.height != self.tableViewHeightConstraint.constant {
            self.tableViewHeightConstraint.constant = max(rowRect.height, 0)
        }
    }
    
    fileprivate func sizeTextView() {
        let minimumHeight: CGFloat = 60
        let newHeight = max(self.textView.sizeThatFits(CGSize(width: self.textView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height, minimumHeight)
        if newHeight != self.textViewHeightConstraint.constant {
            self.textViewHeightConstraint.constant = newHeight
            self.textView.superview?.layoutIfNeeded()
            self.updateInset()
        }
    }
    
    fileprivate func updateInset() {
        var bottomInset = self.scrollView.frame.height
        bottomInset -= self.topLayoutGuide.length
        if let superview = self.textView.superview {
            bottomInset -= superview.frame.height
        }
        
        //The bottom inset shouldn't be less than the keyboard frame. Otherwise the text will go behind the keyboard.
        bottomInset = max(bottomInset, self.keyboardFrame.height)
        
        let inset = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: bottomInset, right: 0)
        self.scrollView.contentInset = inset
        
        let scrollBarInset = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.keyboardFrame.height, right: 0)
        self.scrollView.scrollIndicatorInsets = scrollBarInset
    }
}

// MARK: - UITableViewDataSource

extension CommentComposeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard self.parentComment != nil || self.post != nil else {
            return 0
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let comment = self.parentComment {
            let cell: CommentCell = tableView.dequeueReusableCell(withIdentifier: "comment", for: indexPath) as! CommentCell
            cell.changeComment(comment, state: CommentCellState(isCollapsed: false, indentation: 0))
            
            //Seperator
            cell.showTopSeperator = false
            cell.showBottomSeperator = true
            
            cell.reloadContents()
            return cell
        } else {
            let cell: PostTitlePartCell = tableView.dequeueReusableCell(withIdentifier: "titlethumbnail", for: indexPath) as! PostTitlePartCell
            
            cell.post = self.post
            cell.showThumbnail = false
            
            return cell
        }
        
    }
    
}

// MARK: - UITableViewDelegate

extension CommentComposeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
}

extension CommentComposeViewController: UIScrollViewDelegate {
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView == self.scrollView {
            let topOffset = self.tableView.rectForRow(at: IndexPath(row: 0, section: 0)).height + self.topLayoutGuide.length
            
            let snappingThreshold: CGFloat = 50
            
            if targetContentOffset.pointee.y < topOffset+snappingThreshold && targetContentOffset.pointee.y > topOffset - snappingThreshold {
                targetContentOffset.pointee.y = topOffset
            }
        }
    }
    
}

extension CommentComposeViewController: UITextViewDelegate {
 
    func textViewDidChange(_ textView: UITextView) {
        self.sizeTextView()
    }
    
}

extension CommentComposeViewController: BeamModalPresentation {
    
    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return BeamModalPresentationStyle.formsheet
    }
    
}
