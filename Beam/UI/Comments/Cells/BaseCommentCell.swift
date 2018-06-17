//
//  BaseCommentCell.swift
//  Beam
//
//  Created by Rens Verhoeven on 29-02-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

struct CommentCellState {
    /// This property is set to true when the user has collapsed this cell or one of it's parents.
    var isCollapsed: Bool
    /// The indentation level the comment is at
    var indentation: Int
}

class BaseCommentCell: BeamTableViewCell {
    
    @IBOutlet fileprivate var commentContentView: CommentCellContentView!

    var showTopSeperator: Bool {
        set {
            self.commentContentView.showTopSeperator = newValue
        }
        get {
            return self.commentContentView.showTopSeperator
        }
    }
    
    var showBottomSeperator: Bool {
        set {
            self.commentContentView.showBottomSeperator = newValue
        }
        get {
            return self.commentContentView.showBottomSeperator
        }
    }
    
    var commentIndentation: Int {
        return self.state.indentation
    }
    
    var isCollapsed: Bool {
        return self.state.isCollapsed
    }
    
    /// This property is true when the comment on the cell has changed during the setting, use this property to optimize performance by not changing content that has changed
    var commentDidChange = false
    
    private var state: CommentCellState = CommentCellState(isCollapsed: false, indentation: 0)
    
    var comment: Comment? {
        return self.privateComment
    }
    
    fileprivate var privateComment: Comment? {
        didSet {
            self.commentDidChange = self.comment != oldValue
        }
    }
    
    /// Changes the comment displayed in this cell
    ///
    /// - Parameters:
    ///   - comment: The comment to display
    ///   - state: The state of the comment in this view, tells the cell if it's collapsed or has an indentation
    func changeComment(_ comment: Comment, state: CommentCellState) {
        self.state = state
        self.commentContentView.commentIndentationLevel = state.indentation
        self.privateComment = comment
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.commentContentView.maxNumberOfReplyBorders = CommentsDataSource.maxCommentsDepth - 1
    }
    
    /**
     This methods configures the view for display, this is required to be called in ```cellForRowAtIndexPath:```. This is seperate method to make sure the UI is updated, but no unnessecary calls are made that could impact performance.
     */
    func reloadContents() {
        self.commentContentView.commentIndentationLevel = self.commentIndentation
        self.commentContentView.showBottomSeperator = self.showBottomSeperator
        self.commentContentView.showTopSeperator = self.showTopSeperator
        self.commentContentView.setNeedsDisplay()
    }
    
}
