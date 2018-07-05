//
//  PostToolbarView.swift
//  beam
//
//  Created by Rens Verhoeven on 16-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import AWKGallery
import CherryKit
import Trekker

protocol PostToolbarViewDelegate: class {
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapCommentsOnPost post: Post)
    func postToolbarView(_ toolbarView: PostToolbarView, didTapPointsOnPost post: Post)
    func postToolbarView(_ toolbarView: PostToolbarView, didTapMoreOnPost post: Post)
    func postToolbarView(_ toolbarView: PostToolbarView, didTapUpvoteOnPost post: Post)
    func postToolbarView(_ toolbarView: PostToolbarView, didTapDownvoteOnPost post: Post)
    
    func visibleSubredditForToolbarView(_ toolbarView: PostToolbarView) -> Subreddit?
    
}

extension PostToolbarViewDelegate where Self: UIViewController {
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapUpvoteOnPost post: Post) {
        if post.voteStatus?.intValue != VoteStatus.up.rawValue {
            self.vote(.up, forPost: post, toolbarView: toolbarView)
        } else {
            self.vote(.neutral, forPost: post, toolbarView: toolbarView)
        }
    }
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapDownvoteOnPost post: Post) {
        if post.voteStatus?.intValue != VoteStatus.down.rawValue {
            self.vote(.down, forPost: post, toolbarView: toolbarView)
        } else {
            self.vote(.neutral, forPost: post, toolbarView: toolbarView)
        }
    }
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapCommentsOnPost post: Post) {
        guard !(self is PostDetailEmbeddedViewController) || self.shownInGallery() else {
            return
        }
        Trekker.default.track(event: TrekkerEvent(event: "Open comments"))
        
        if self.shownInGallery() || self.navigationController == nil {
            let storyboard = UIStoryboard(name: "Comments", bundle: nil)
            let commentsNavigationController = storyboard.instantiateInitialViewController() as! BeamNavigationController
            let commentsViewController = commentsNavigationController.topViewController as! CommentsViewController
            
            let commentsQuery = CommentCollectionQuery()
            commentsQuery.post = post
            commentsViewController.query = commentsQuery
            commentsNavigationController.useScalingTransition = false
            
            self.modallyPresentToolBarActionViewController(commentsNavigationController, toolbarView: toolbarView)
            if UserSettings[.postMarking] {
                post.markVisited()
            }
        } else {
            let detailViewController = PostDetailViewController(post: post, contextSubreddit: toolbarView.delegate?.visibleSubredditForToolbarView(toolbarView))
            detailViewController.scrollToCommentsOnLoad = true
            self.navigationController?.show(detailViewController, sender: nil)
            if UserSettings[.postMarking] {
                post.markVisited()
            }
        }
    }
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapPointsOnPost post: Post) {
        postToolbarView(toolbarView, didTapCommentsOnPost: post)
    }
    
    func postToolbarView(_ toolbarView: PostToolbarView, didTapMoreOnPost post: Post) {
        let activityViewController = ShareActivityViewController(object: post)
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> Void in
            if completed {
                Trekker.default.track(event: TrekkerEvent(event: "Share post", properties: [
                    "Activity type": activityType?.rawValue ?? "Unknown",
                    "Used reddit link": NSNumber(value: true)
                    ]))
            }
        }
        
        self.modallyPresentToolBarActionViewController(activityViewController, toolbarView: toolbarView, sender: toolbarView.moreButton)
    }
    
    fileprivate func vote(_ status: VoteStatus, forPost post: Post, toolbarView: PostToolbarView) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            let alertController = UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.VotePost)
            self.modallyPresentToolBarActionViewController(alertController, toolbarView: toolbarView)
            return
        }
        
        guard post.locked.boolValue == false && post.archived.boolValue == false else {
            if let viewController = self as? NoticeHandling {
                let message = post.locked.boolValue == true ? AWKLocalizedString("locked-error-message") : AWKLocalizedString("archived-error-message")
                let title = post.locked.boolValue == true ? AWKLocalizedString("locked") : AWKLocalizedString("archived")
                if self.shownInGallery() {
                    let alertController = BeamAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addCloseAction()
                    self.modallyPresentToolBarActionViewController(alertController, toolbarView: toolbarView)
                } else {
                    viewController.presentErrorMessage(message)
                }
                
            }
            return
        }
        
        if UserSettings[.postMarking] {
            post.markVisited()
        }
        
        let oldVoteStatus = VoteStatus(rawValue: post.voteStatus?.intValue ?? 0) ?? VoteStatus.neutral
        post.updateScore(status, oldVoteStatus: oldVoteStatus)
        post.voteStatus = NSNumber(value: status.rawValue)
        status.soundType.play()
        
        if #available(iOS 10, *), [VoteStatus.up, VoteStatus.down].contains(status) {
            let feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.selectionChanged()
        }
        
        let operation = post.voteOperation(status, authenticationController: AppDelegate.shared.authenticationController)
        DataController.shared.executeOperations([operation]) { [weak self] (error: Error?) -> Void in
            post.managedObjectContext?.perform {
                if let error = error {
                    print("Error \(error)")
                    post.updateScore(oldVoteStatus, oldVoteStatus: status)
                    post.voteStatus = NSNumber(value: oldVoteStatus.rawValue)
                    self?.presentVoteError(error)
                }
            }
        }
    }
    
    fileprivate func shownInGallery() -> Bool {
        if self.presentedViewController is AWKGalleryViewController {
            return true
        } else if AppDelegate.shared.galleryWindow?.rootViewController != nil {
            return true
        }
        return false
    }
    
    fileprivate func modallyPresentToolBarActionViewController(_ viewController: UIViewController, toolbarView: PostToolbarView, sender: UIControl? = nil) {
        if let activityViewController = viewController as? UIActivityViewController, self.traitCollection.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = toolbarView
            if let sender = sender {
                activityViewController.popoverPresentationController?.sourceRect = sender.frame
            }
            activityViewController.title = "Share"
        }
        if let gallery = self.presentedViewController as? AWKGalleryViewController {
            gallery.present(viewController, animated: true, completion: nil)
        } else if let galleryRootViewController = AppDelegate.shared.galleryWindow?.rootViewController, let topViewController = AppDelegate.topViewController(galleryRootViewController) {
            topViewController.present(viewController, animated: true, completion: nil)
        } else {
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func presentVoteError(_ error: Error?) {
        if let error = error as NSError? {
            if let noticeHandler = self as? NoticeHandling {
                if error.code == NSURLErrorNotConnectedToInternet && error.domain == NSURLErrorDomain {
                    noticeHandler.presentErrorMessage(AWKLocalizedString("error-vote-internet"))
                } else {
                    noticeHandler.presentErrorMessage(AWKLocalizedString("error-vote"))
                }
            }
        }

    }
    
    func  visibleSubredditForToolbarView(_ toolbarView: PostToolbarView) -> Subreddit? {
        return nil
    }
    
}

class PostToolbarView: BeamView {

    weak var delegate: PostToolbarViewDelegate?
    
    var popoverController: UIPopoverPresentationController?
    
    weak var post: Post? {
        didSet {
            UIView.performWithoutAnimation { () -> Void in
                self.updateContent()
            }
        }
    }
    
    override var isOpaque: Bool {
        didSet {
            if self.isOpaque != oldValue {
                self.displayModeDidChange()
            }
        }
    }
    
    var shouldShowSeperator = true {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    fileprivate let commentsButton: BeamPlainButton = {
        let button = BeamPlainButton(frame: CGRect())
        button.setImage(UIImage(named: "actionbar_comments"), for: UIControlState())
        button.setTitle("comments", for: UIControlState())
        return button
    }()
    
    fileprivate let pointsButton: BeamPlainButton = {
        let button = BeamPlainButton(frame: CGRect())
        button.setImage(UIImage(named: "actionbar_points"), for: UIControlState())
        button.setTitle("points", for: UIControlState())
        return button
    }()
    
    fileprivate let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "actionbar_more"), for: UIControlState())
        return button
    }()
    
    fileprivate let upvoteButton: VoteButton = {
        let voteButton = VoteButton()
        voteButton.arrowDirection = .up
        return voteButton
    }()
    
    fileprivate let downvoteButton: VoteButton = {
        let voteButton = VoteButton()
        voteButton.arrowDirection = .down
        return voteButton
    }()
    
    fileprivate var tintedButtons = [UIButton]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    fileprivate func setupView() {
        self.isOpaque = true
        self.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 12)
        
        self.configureLabeledButton(self.commentsButton)
        self.configureLabeledButton(self.pointsButton)
        
        self.commentsButton.addTarget(self, action: #selector(PostToolbarView.viewComments(_:)), for: .touchUpInside)
        self.pointsButton.addTarget(self, action: #selector(PostToolbarView.viewPoints(_:)), for: .touchUpInside)
        self.moreButton.addTarget(self, action: #selector(PostToolbarView.more(_:)), for: .touchUpInside)
        self.downvoteButton.addTarget(self, action: #selector(PostToolbarView.downvote(_:)), for: .touchUpInside)
        self.upvoteButton.addTarget(self, action: #selector(PostToolbarView.upvote(_:)), for: .touchUpInside)
        
        self.tintedButtons.append(self.commentsButton)
        self.addSubview(self.commentsButton)
        
        self.tintedButtons.append(self.pointsButton)
        self.addSubview(self.pointsButton)
        
        self.tintedButtons.append(self.moreButton)
        self.addSubview(self.moreButton)
        
        self.addSubview(self.downvoteButton)
        
        self.addSubview(self.upvoteButton)

    }
    
    fileprivate func updateContent() {
        self.commentsButton.setTitle("\(self.post?.commentCount?.intValue ?? 0)", for: UIControlState.normal)
        self.pointsButton.setTitle(self.pointsTitle(), for: UIControlState.normal)
            
        self.upvoteButton.voted = self.post?.voteStatus?.intValue == VoteStatus.up.rawValue
        self.downvoteButton.voted = self.post?.voteStatus?.intValue == VoteStatus.down.rawValue
        
        self.setNeedsLayout()
    }
    
    fileprivate func pointsTitle() -> String {
        guard let score = self.post?.score else {
            return "0"
        }
        let floatValue = score.floatValue / 1000
        if floatValue >= 100 {
            return String(format: "%.0fk", floatValue)
        } else if floatValue >= 10 {
            return String(format: "%.1fk", floatValue)
        } else {
            return score.stringValue
        }
    }
    
    // MARK: - Convenience
    
    fileprivate func configureLabeledButton(_ button: UIButton) {
        let font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        let insetAmount: CGFloat = 2.0
        
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
        button.titleLabel?.font = font
    }
    
    // MARK: - Actions
    
    @objc func viewComments(_ sender: UIButton?) {
        if let post = self.post {
            self.delegate?.postToolbarView(self, didTapCommentsOnPost: post)
        }
    }
    
    @objc func viewPoints(_ sender: UIButton?) {
        if let post = self.post {
            self.delegate?.postToolbarView(self, didTapPointsOnPost: post)
        }
    }
    
    @objc func more(_ sender: UIButton?) {
        if let post = self.post {
            self.delegate?.postToolbarView(self, didTapMoreOnPost: post)
        }
    }
    
    @objc func upvote(_ sender: UIButton?) {
        if let post = self.post, !self.upvoteButton.animating && !self.downvoteButton.animating {
            self.delegate?.postToolbarView(self, didTapUpvoteOnPost: post)
            self.upvoteButton.setVoted(self.post?.voteStatus?.intValue == VoteStatus.up.rawValue, animated: true)
            self.downvoteButton.setVoted(self.post?.voteStatus?.intValue == VoteStatus.down.rawValue, animated: true)
        }
    }
    
    @objc func downvote(_ sender: UIButton?) {
        if let post = self.post, !self.upvoteButton.animating && !self.downvoteButton.animating {
            self.delegate?.postToolbarView(self, didTapDownvoteOnPost: post)
            self.downvoteButton.setVoted(self.post?.voteStatus?.intValue == VoteStatus.down.rawValue, animated: true)
            self.upvoteButton.setVoted(self.post?.voteStatus?.intValue == VoteStatus.up.rawValue, animated: true)
        }
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        if self.shouldShowSeperator {
            let seperatorPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: rect.width, height: 0.5))
            var seperatorColor = UIColor.beamGreyExtraExtraLight()
            if self.displayMode == .dark {
                seperatorColor = UIColor.beamDarkTableViewSeperatorColor()
            }
            seperatorColor.setFill()
            seperatorPath.fill()
        }
    }
    
    // MARK: - Display mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let tintColor = DisplayModeValue(UIColor(red: 170 / 255.0, green: 168 / 255.0, blue: 179 / 255.0, alpha: 1), darkValue: UIColor(red: 153 / 255.0, green: 153 / 255.0, blue: 153 / 255.0, alpha: 1))
        if self.tintColor != tintColor {
            self.tintColor = tintColor
        }
        self.upvoteButton.color = tintColor
        self.downvoteButton.color = tintColor
        if self.tintAdjustmentMode != UIViewTintAdjustmentMode.normal {
        	self.tintAdjustmentMode = UIViewTintAdjustmentMode.normal
        }

        UIView.performWithoutAnimation { () -> Void in
            for button in self.tintedButtons {
                if button.tintColor != tintColor {
                    button.tintColor = tintColor
                }
                button.setTitleColor(tintColor, for: UIControlState())
                button.setTitleColor(tintColor, for: UIControlState.highlighted)
            }
            
            //Update opaque views
            let opaqueViews = [self.commentsButton, self.pointsButton, self.moreButton, self.downvoteButton, self.upvoteButton]
            
            var backgroundColor = UIColor.white
            if self.displayMode == .dark {
                backgroundColor = UIColor.beamDarkContentBackgroundColor()
            }
            if !self.isOpaque {
                backgroundColor = UIColor.clear
            }
            for view in opaqueViews {
                if let button = view as? UIButton {
                    button.titleLabel?.backgroundColor = backgroundColor
                }
                view.backgroundColor = backgroundColor
            }
            self.backgroundColor = backgroundColor
            
            for view in opaqueViews {
                if let button = view as? UIButton {
                    button.titleLabel?.isOpaque = self.isOpaque
                }
                view.isOpaque = self.isOpaque
            }
            
            //Call setNeedsDisplay to update the seperator
            self.setNeedsDisplay()
            
            self.setNeedsLayout()
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        /*
        This works around a bug with UIAlertController and UIAlertView in iOS 8.
        Sometimes after returning the views have the color of the UIWindow they are on, instead of the custom set tintColor or the superview tintColor
        */
        UIView.performWithoutAnimation { () -> Void in
            self.tintAdjustmentMode = .normal
            for button in self.tintedButtons {
                button.tintAdjustmentMode = .normal
            }
            
            self.setNeedsLayout()
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layoutLeftSideButtons()
        self.layoutRightSideButtons()
    }
    
    func layoutLeftSideButtons() {
        let buttonSpacing: CGFloat = 10.0
        //Remove 2 because of the top border
        let barHeight = self.bounds.height - 2
        
        var xPosition = self.layoutMargins.left
        //Because of the increased size of the comments button, substract 10 extra points
        xPosition -= 10
        
        var commentsButtonSize = self.commentsButton.intrinsicContentSize
        commentsButtonSize.height = barHeight
        commentsButtonSize.width += 20
        let commentsButtonFrame = CGRect(origin: CGPoint(x: xPosition, y: (self.bounds.size.height - commentsButtonSize.height) / 2), size: commentsButtonSize)
        self.commentsButton.frame = commentsButtonFrame
        
        xPosition += commentsButtonSize.width + buttonSpacing
        //Because of the increased size of the points button, substract 20 extra points
        xPosition -= 20
        
        var pointsButtonSize = self.pointsButton.intrinsicContentSize
        pointsButtonSize.height = barHeight
        pointsButtonSize.width += 20
        let pointsButtonFrame = CGRect(origin: CGPoint(x: xPosition, y: (self.bounds.size.height - pointsButtonSize.height) / 2), size: pointsButtonSize)
        self.pointsButton.frame = pointsButtonFrame
    }
    
    func layoutRightSideButtons() {
        let buttonSpacing: CGFloat = 18.0
        //Remove 2 because of the top border
        let barHeight = self.bounds.height - 2
        
        var xPosition = self.bounds.width - self.layoutMargins.right
        //Because of the increased size of the vote buttons, add 10 extra points
        xPosition += 10
        
        var upvoteButtonSize = self.upvoteButton.intrinsicContentSize
        upvoteButtonSize.height = barHeight
        upvoteButtonSize.width += 20
        let upvoteButtonFrame = CGRect(origin: CGPoint(x: xPosition - upvoteButtonSize.width, y: (self.bounds.size.height - upvoteButtonSize.height) / 2), size: upvoteButtonSize)
        self.upvoteButton.frame = upvoteButtonFrame
        
        xPosition -= upvoteButtonSize.width + buttonSpacing
        //Because of the bigger and ivisible size of the vote button, add 20 extra points so the placement is still the same (10 points each side, times 2 buttons)
        xPosition += 20
        
        var downvoteButtonSize = self.downvoteButton.intrinsicContentSize
        downvoteButtonSize.height = barHeight
        downvoteButtonSize.width += 20
        let downvoteButtonFrame = CGRect(origin: CGPoint(x: xPosition - downvoteButtonSize.width, y: (self.bounds.size.height - downvoteButtonSize.height) / 2), size: downvoteButtonSize)
        self.downvoteButton.frame = downvoteButtonFrame
        
        xPosition -= downvoteButtonSize.width + buttonSpacing
        //Because of the bigger and ivisible size of the vote button, add 10 extra points so the placement is correct of the more button
        xPosition += 20
        
        var moreButtonSize = self.moreButton.intrinsicContentSize
        moreButtonSize.height = barHeight
        moreButtonSize.width += 20
        let moreButtonFrame = CGRect(origin: CGPoint(x: xPosition - moreButtonSize.width, y: (self.bounds.size.height - moreButtonSize.height) / 2), size: moreButtonSize)
        self.moreButton.frame = moreButtonFrame
    }
}
