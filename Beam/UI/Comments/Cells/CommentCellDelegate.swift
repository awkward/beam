//
//  CommentCellDelegate.swift
//  Beam
//
//  Created by Rens Verhoeven on 30/01/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CherryKit
import CoreData
import Trekker

protocol CommentCellDelegate: class {
    
    //Required
    func commentsDataSource(for cell: CommentCell) -> CommentsDataSource
    func commentCell(_ cell: CommentCell, didProduceErrorMessage message: String)
    
    //Optional, implemented in extension below
    func commentCell(_ cell: CommentCell, didTapUsernameOnComment comment: Comment)
    func commentCell(_ cell: CommentCell, didTapComment comment: Comment)
    func commentCell(_ cell: CommentCell, didSelectUpvoteOnComment comment: Comment)
    func commentCell(_ cell: CommentCell, didSelectDownvoteOnComment comment: Comment)
    func commentCell(_ cell: CommentCell, didSelectMoreOnComment comment: Comment)
    func commentCell(_ cell: CommentCell, didSelectReplyOnComment comment: Comment)
    func commentCell(_ cell: CommentCell, didHoldOnComment comment: Comment)
    
    func commentCell(_ cell: CommentCell, didTapLinkPreview comment: Comment, url: URL)
    func commentCell(_ cell: CommentCell, didTapImagePreview comment: Comment, mediaObjects: [MediaObject])
    
}

extension CommentCellDelegate where Self: UITableViewController {
    
    func commentCell(_ cell: CommentCell, didTapUsernameOnComment comment: Comment) {
        self.showProfileForComment(comment)
    }
    
    func commentCell(_ cell: CommentCell, didSelectMoreOnComment comment: Comment) {
        self.showShareForComment(comment, cell: cell)
    }
    
    func commentCell(_ cell: CommentCell, didTapComment comment: Comment) {
        let dataSource = self.commentsDataSource(for: cell)
        dataSource.toggleCollapseForComment(comment)
        
        if #available(iOS 10, *) {
            let feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.selectionChanged()
        }
        
        self.tableView.reloadData()
        
        //If the collapsed IndexPath isn't visible in the tableView at all, we scroll it to a visible position to make sure both the next comment and the collapsed comment are visible to the user
        if let indexPath: IndexPath = dataSource.indexPath(forComment: comment), dataSource.isCommentCollapsed(comment) {
            self.scrollIndexPathToVisible(indexPath)
        }
    }
    
    func commentCell(_ cell: CommentCell, didSelectUpvoteOnComment comment: Comment) {
        if VoteStatus(rawValue: comment.voteStatus?.intValue ?? 0) == VoteStatus.up {
            self.voteComment(comment, direction: VoteStatus.neutral, cell: cell)
        } else {
            self.voteComment(comment, direction: VoteStatus.up, cell: cell)
        }
        cell.reloadContents()
    }
    
    func commentCell(_ cell: CommentCell, didSelectDownvoteOnComment comment: Comment) {
        if VoteStatus(rawValue: comment.voteStatus?.intValue ?? 0) == VoteStatus.down {
            self.voteComment(comment, direction: VoteStatus.neutral, cell: cell)
        } else {
            self.voteComment(comment, direction: VoteStatus.down, cell: cell)
        }
        cell.reloadContents()
    }
    
    func commentCell(_ cell: CommentCell, didHoldOnComment comment: Comment) {
        //Disable the hold to collapse parent in the commentsViewController if a parent comment is set. This means we are in a thread
        let dataSource = self.commentsDataSource(for: cell)
        if dataSource.query.parentComment == nil {
            var collapsedIndexPath: IndexPath?
            if let superComment = dataSource.superParentForComment(comment) {
                dataSource.toggleCollapseForComment(superComment)
                collapsedIndexPath = dataSource.indexPath(forComment: superComment)
            } else if comment.parent == nil {
                dataSource.toggleCollapseForComment(comment)
                collapsedIndexPath = dataSource.indexPath(forComment: comment)
            }
            
            if collapsedIndexPath != nil {
                if #available(iOS 10, *) {
                    let feedbackGenerator = UISelectionFeedbackGenerator()
                    feedbackGenerator.prepare()
                    feedbackGenerator.selectionChanged()
                }
            }
            
            self.tableView.reloadData()
            
            //If the collapsed IndexPath isn't visible in the tableView at all, we scroll it to a visible position to make sure both the next comment and the collapsed comment are visible to the user
            if let indexPath: IndexPath = collapsedIndexPath, dataSource.isCommentCollapsed(comment) {
                self.scrollIndexPathToVisible(indexPath)
            }
        }
    }
    
    func commentCell(_ cell: CommentCell, didSelectReplyOnComment comment: Comment) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.General), animated: true, completion: nil)
            return
        }
        
        let dataSource = self.commentsDataSource(for: cell)
        
        guard dataSource.query.post?.locked.boolValue == false && dataSource.query.post?.archived.boolValue == false else {
            if dataSource.query.post?.locked.boolValue == true {
                self.commentCell(cell, didProduceErrorMessage: AWKLocalizedString("locked-error-message"))
            } else {
                self.commentCell(cell, didProduceErrorMessage: AWKLocalizedString("archived-error-message"))
            }
            return
        }
        
        let storyBoard = UIStoryboard(name: "Comments", bundle: nil)
        let navigationController = storyBoard.instantiateViewController(withIdentifier: "compose") as! CommentsNavigationController
        navigationController.useInteractiveDismissal = false
        let composeViewController = navigationController.topViewController as! CommentComposeViewController
        composeViewController.parentComment = comment
        composeViewController.post = dataSource.query.post
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func commentCell(_ cell: CommentCell, didTapLinkPreview comment: Comment, url: URL) {
        if ExternalLinkOpenOption.shouldShowPrivateBrowsingWarning() {
            ExternalLinkOpenOption.showPrivateBrowsingWarning(url, on: self)
        } else {
            if let viewController = AppDelegate.shared.openExternalURLWithCurrentBrowser(url) {
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
    
    func commentCell(_ cell: CommentCell, didTapImagePreview comment: Comment, mediaObjects: [MediaObject]) {
        //We do nothing
        print("didTapImagePreview has no default implementation. Please implement it to use it")
    }
    
    // MARK: - Comment action methods
    
    fileprivate func showProfileForComment(_ comment: Comment) {
        if let username = comment.author, username != "[deleted]" {
            let navigationController = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as! BeamColorizedNavigationController
            let profileViewController = navigationController.viewControllers.first as! ProfileViewController
            profileViewController.username = username
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    fileprivate func showShareForComment(_ comment: Comment, cell: CommentCell) {
        if comment.hasBeenDeleted == false {
            let activityViewController = ShareActivityViewController(object: comment)
            activityViewController.excludedActivityTypes = [UIActivityType.copyToPasteboard]
            activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> Void in
                if completed {
                    Trekker.default.track(event: TrekkerEvent(event: "Share comment", properties: [
                        "Activity type": activityType?.rawValue ?? "Unknown",
                        "Used reddit link": NSNumber(value: true)
                        ]))
                }
            }
            activityViewController.popoverPresentationController?.sourceRect = cell.frame
            activityViewController.popoverPresentationController?.sourceView = self.tableView
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func voteComment(_ comment: Comment, direction: VoteStatus, cell: CommentCell) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.VoteComment), animated: true, completion: nil)
            return
        }
        
        let dataSource = self.commentsDataSource(for: cell)
        
        guard dataSource.query.post?.locked.boolValue == false && dataSource.query.post?.archived.boolValue == false else {
            if dataSource.query.post?.locked.boolValue == true {
                self.commentCell(cell, didProduceErrorMessage: AWKLocalizedString("locked-error-message"))
            } else {
                self.commentCell(cell, didProduceErrorMessage: AWKLocalizedString("archived-error-message"))
            }
            return
        }
        
        let oldVoteStatus = VoteStatus(rawValue: comment.voteStatus?.intValue ?? 0) ?? VoteStatus.neutral
        comment.updateScore(direction, oldVoteStatus: oldVoteStatus)
        comment.voteStatus = NSNumber(value: direction.rawValue)
        direction.soundType.play()
        
        if #available(iOS 10, *), [VoteStatus.up, VoteStatus.down].contains(direction) {
            let feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.selectionChanged()
        }
        
        let operation = comment.voteOperation(direction, authenticationController: AppDelegate.shared.authenticationController)
        DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if let error = error as NSError? {
                    comment.updateScore(oldVoteStatus, oldVoteStatus: direction)
                    comment.voteStatus = NSNumber(value: oldVoteStatus.rawValue)
                    if error.code == NSURLErrorNotConnectedToInternet && error.domain == NSURLErrorDomain {
                        self.commentCell(cell, didProduceErrorMessage: AWKLocalizedString("error-vote-internet"))
                    } else {
                        self.commentCell(cell, didProduceErrorMessage: AWKLocalizedString("error-vote"))
                    }
                }
            })
        })
        
    }
    
    /// Scrolls to the given indexPath to the top of the tableView, only if it's not visible in tableView
    ///
    /// - Parameter indexPath: The indexPath to scroll to if needed
    private func scrollIndexPathToVisible(_ indexPath: IndexPath) {
        guard let superview = self.tableView.superview else {
            return
        }
        let rowRect = self.tableView.convert(self.tableView.rectForRow(at: indexPath), to: superview)
        let visibleRect = UIEdgeInsetsInsetRect(CGRect(origin: CGPoint(), size: self.tableView.bounds.size), self.tableView.contentInset)
        
        if !visibleRect.contains(rowRect) {
            self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
}
