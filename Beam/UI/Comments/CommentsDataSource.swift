//
//  CommentsDataSource.swift
//  Beam
//
//  Created by Rens Verhoeven on 02-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

class CommentsDataSource: NSObject {
    
    static var maxCommentsDepth: Int {
        let screenWidth = UIScreen.main.bounds.size.width
        if screenWidth > 375 {
            return 9
        } else if screenWidth > 350 {
            return 8
        } else {
            return 5
        }
    }
    
    var query: CommentCollectionQuery = CommentCollectionQuery()
    
    var collapsedComments = [Comment]()
    
    var threads: [[Comment]]? = [[Comment]]()
    
    var status: CollectionControllerStatus {
        return self.collectionController.status
    }
    
    let collectionController: CollectionController = {
        let controller = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        controller.postProcessOperations = { () -> ([Operation]) in
            return [MarkdownParsingOperation()]
        }
        return controller
    }()
    
    var indexPathSectionOffset = 0
    
    //Used to determine the loading indicator for the Load More Comments cells
    fileprivate var loadingMoreComment: MoreComment?
    
    // MARK: - Data
    
    func fetchComments(_ completionHandler: @escaping (_ collectionID: NSManagedObjectID?, _ error: Error?) -> Void) {
        self.collectionController.cancelFetching()
        self.query.depth = CommentsDataSource.maxCommentsDepth
        self.collectionController.query = self.query
        self.collectionController.startInitialFetching(true) { (collectionID, error) -> Void in
            self.createThreads()
            completionHandler(collectionID, error)
        }
    }
    
    func cancelRequests() {
        self.collectionController.cancelFetching()
    }
    
    /**
     Get the comments at a specific index in the threads
     
     - parameter index: The index of the thread you want ot get
     
     - returns: An array of comments in the thread, this is the flattened array
     */
    func commentsAtIndex(_ index: Int) -> [Comment]? {
        guard let threads = self.threads, index < threads.count else {
            return nil
        }
        return threads[index]
    }
    
    /**
     Get a comment at a specific indexPath.
     
     - parameter indexPath: The indexPath to get the comment, this should begin with section 0 and row 0
     
     - returns: The comment at the given indexPath if available
     */
    func commentAtIndexPath(_ indexPath: IndexPath) -> Comment? {
        guard let threads = self.threads, indexPath.section < threads.count else {
            return nil
        }
        let comments = threads[indexPath.section]
        guard indexPath.row < comments.count else {
            return nil
        }
        return comments[indexPath.row]
    }
    
    func indexPath(forComment comment: Comment, withOffset: Bool = true) -> IndexPath? {
        guard let threads: [[Comment]] = self.threads else {
            return nil
        }
        
        var section: Int = 0
        if withOffset {
            section = self.indexPathSectionOffset
        }
        for thread: [Comment] in threads {
            if let index = thread.index(of: comment) {
                let indexPath = IndexPath(row: index, section: section)
                return indexPath
            }
            section += 1
        }
        return nil
    }
    
    /**
     Creates the comment threads from a ObjectCollection
     */
    func createThreads() {
        AppDelegate.shared.managedObjectContext.performAndWait { () -> Void in
            if let collectionID = self.collectionController.collectionID, let collection = AppDelegate.shared.managedObjectContext.object(with: collectionID) as? ObjectCollection, let topLevelComments = collection.objects?.array as? [Comment] {
                var threads = [[Comment]]()
                for comment in topLevelComments {
                    var section = [Comment]()
                    section.append(comment)
                    section.append(contentsOf: self.commentReplies(comment, currentLevel: 1))
                    threads.append(section)
                }
                self.threads = threads
            }
        }
    }
    
    /**
     Inserts a comment into the datasource. However it might not add it to the data store!
    
     - Parameters:
       - comment: The comment to insert
     - Returns: The indexpath which can be used to add a row or section to the tableView
    */
    func insertComment(_ comment: Comment) -> IndexPath? {
        guard let parent = comment.parent as? Comment, let threads = self.threads else {
            self.threads?.append([comment])
            return self.indexPath(forComment: comment)
        }
        var threadIndex = 0
        for var thread in threads {
            if let index = thread.index(of: parent) {
                AppDelegate.shared.managedObjectContext.performAndWait {
                    var replies = NSMutableOrderedSet()
                    if let existingReplies = parent.replies {
                        replies = existingReplies.mutableCopy() as! NSMutableOrderedSet
                    }
                    if replies.index(of: comment) != NSNotFound {
                        replies.add(comment)
                    }
                    parent.replies = replies
                }
                if index + 1 < thread.count {
                    thread.insert(comment, at: index + 1)
                } else {
                    thread.append(comment)
                }
                self.threads?[threadIndex] = thread
                return self.indexPath(forComment: comment)
            }
            threadIndex += 1
        }
        return nil
    }
    
    /**
     Load the children of a MoreComment. This will also recreate the threads
     
     - parameter comment: The MoreComment to load the children of
     - parameter completionHandler: A completion handler, called when the operation has completed or an error occured
     */
    func loadMoreCommentChildren(_ comment: MoreComment, completionHandler: @escaping (_ error: Error?) -> Void) {
        if self.loadingMoreComment != nil {
            completionHandler(NSError.beamError(-20, localizedDescription: "Loading more comments while another is in progress is not allowed"))
            return
        }
        if let post = self.query.post, let collectionID = self.collectionController.collectionID, let operations = comment.moreChildrenOperation(post, sort: self.query.sortType, commentsCollectionID: collectionID, authenticationcontroller: AppDelegate.shared.authenticationController) {
            self.loadingMoreComment = comment
            DataController.shared.executeAndSaveOperations(operations, context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                self.loadingMoreComment = nil
                self.createThreads()
                completionHandler(error)
            })
        } else {
            completionHandler(nil)
        }
    }
    
    //This private method is used a a recursive loop to make the comment tree
    fileprivate func commentReplies(_ parentComment: Comment, currentLevel: Int) -> [Comment] {
        var comments = [Comment]()
        if let replies = parentComment.replies?.array as? [Comment] {
            for comment in replies {
                if !self.isCommentFullyCollapsed(comment) {
                    comments.append(comment)
                    let level = currentLevel + 1
                    if level < CommentsDataSource.maxCommentsDepth {
                        comments.append(contentsOf: self.commentReplies(comment, currentLevel: level))
                    } else {
                        if let comment = comment.replies?.firstObject as? Comment {
                            comments.append(comment)
                        }
                        
                    }
                }
            }
            
        }
        return comments
    }
    
    // MARK: - Comment properties
    
    /**
     Returns the relative indentation level for the comment. The parentComment of the qeuery is taken as the begin level if available
     
     - parameter comment: The comment to get the level
     
     - returns: The level as integer between 0 and 100
     */
    func indentationForComment(_ comment: Comment) -> Int {
        if self.self.query.parentComment != nil && comment == query.parentComment {
            return 0
        } else if comment.parent == nil {
            if self.query.parentComment != nil {
                return 1
            } else {
                return 0
            }
        } else {
            return 1 + self.indentationForComment(comment.parent as! Comment)
        }
    }
    
    /**
     Get the first comment in the thread of comments. The so called super parent of the comment
     
     - parameter comment: The comment to get the super parent of
     
     - returns: The super parent comment
     */
    func superParentForComment(_ comment: Comment) -> Comment? {
        if let parentComment = comment.parent as? Comment {
            return self.superParentForComment(parentComment)
        } else {
            return comment
        }
    }
    
    /**
     Toggle the collapsed state on a comment
     
     - parameter comment: The comment to collapse or expand
     */
    func toggleCollapseForComment(_ comment: Comment) {
        if self.collapsedComments.contains(comment) {
            self.collapsedComments.remove(at: self.collapsedComments.index(of: comment)!)
        } else {
            self.collapsedComments.append(comment)
        }
        self.createThreads()
    }
    
    /**
     Returns if the comment is collapsed in the thread or not
     
     - parameter comment: The comment to check if collapsed
     
     - returns: True when collapsed
     */
    func isCommentCollapsed(_ comment: Comment) -> Bool {
        if self.collapsedComments.contains(comment) {
            return true
        }
        if let parentComment = comment.parent as? Comment {
            return self.isCommentCollapsed(parentComment)
        }
        return false
    }
    
    /**
     Returns if the comment is fully collapsed, this is when nothing of the comment is shown, not even a username
     
     - parameter comment: The comment to check the state
     
     - returns: true if fully collapsed
     */
    func isCommentFullyCollapsed(_ comment: Comment) -> Bool {
        if self.collapsedComments.contains(comment) {
            if let parentComment = comment.parent as? Comment, self.isCommentCollapsed(parentComment) {
                return true
            }
            return false
        }
        return self.isCommentCollapsed(comment)
    }
    
    /**
     Returns if the comment is outside of the thread depth limit.
     
     - parameter comment: The comment to check
     
     - returns: True if the comment is outside of the depth
     */
    func isCommentOutsideOfDepthLimit(_ comment: Comment) -> Bool {
        let indentation = self.indentationForComment(comment)
        return indentation >= CommentsDataSource.maxCommentsDepth
    }

    // MARK: - UITableView methods
    
    /**
    Register the needed cells for the tableView
    
    - parameter tableView: The tableView to register the cells to
    */
    func registerCells(_ tableView: UITableView) {
        tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "comment")
        tableView.register(UINib(nibName: "LoadMoreCommentsCell", bundle: nil), forCellReuseIdentifier: "load_more")
        tableView.register(UINib(nibName: "ContinueCommentThreadCell", bundle: nil), forCellReuseIdentifier: "continue_thread")
    }
    
    func commentCell(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> BaseCommentCell? {
        let newIndexPath = IndexPath(row: (indexPath as IndexPath).row, section: (indexPath as IndexPath).section - self.indexPathSectionOffset)
        if let comment = self.commentAtIndexPath(newIndexPath) {
            var cell: BaseCommentCell!
            if self.isCommentOutsideOfDepthLimit(comment) {
                let threadCell = tableView.dequeueReusableCell(withIdentifier: "continue_thread", for: indexPath) as! ContinueCommentThreadCell
                
                threadCell.selectionStyle = .default
                
                cell = threadCell
            } else if comment is MoreComment {
                cell = tableView.dequeueReusableCell(withIdentifier: "load_more", for: indexPath) as! LoadMoreCommentsCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "comment", for: indexPath) as! CommentCell
            }
            
            self.configureCell(cell, indexPath: newIndexPath)
            
            return cell
        }
        return nil
    }
    
    func configureCell(_ cell: BaseCommentCell, indexPath: IndexPath) {
        guard let comment = self.commentAtIndexPath(indexPath) else {
            return
        }
        if cell is ContinueCommentThreadCell {
            
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
        } else if let moreCell = cell as? LoadMoreCommentsCell {
            
            moreCell.selectionStyle = .default
            moreCell.loading = comment == self.loadingMoreComment
        
        } else if cell is CommentCell {
            
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
        }
        cell.changeComment(comment, state: CommentCellState(isCollapsed: self.isCommentCollapsed(comment), indentation: self.indentationForComment(comment)))
        
        //Seperator
        cell.showTopSeperator = (indexPath as IndexPath).row != 0
        cell.showBottomSeperator = false
        
        cell.reloadContents()
    }
    
    func commentCellHeightForComment(_ comment: Comment) -> CGFloat {
        if self.isCommentOutsideOfDepthLimit(comment) {
            return 44
        } else if comment is MoreComment {
            return 44
        } else {
            if self.collapsedComments.contains(comment) {
                if let parentComment = comment.parent as? Comment, self.isCommentCollapsed(parentComment) {
                    return 0
                }
                return 40
            }
            if self.isCommentCollapsed(comment) {
                return 0
            }
        }
        return UITableViewAutomaticDimension
    }
    
}
