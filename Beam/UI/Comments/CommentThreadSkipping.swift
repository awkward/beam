//
//  CommentThreadSkipperController.swift
//  Beam
//
//  Created by Rens Verhoeven on 09/01/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

/// Adds a method to easily skip to the next thread in a comment view
protocol CommentThreadSkipping {
    
    /// The tableView, for a UIViewController this can be forwarded from the embeded ViewController
    var tableView: UITableView? { get }
    
    /// The current thread number, starting at 0 for the first thread
    var currentThread: Int? { get }
    
    /// Scrolls the tableView to the next thread, animated
    func scrollToNextCommentThread()
    
}

extension CommentThreadSkipping {
    
    var currentThread: Int? {
        guard let tableView = self.tableView, let superview = tableView.superview else {
            return nil
        }
        //Get the visible indexPaths of a tableView in the actually visible rect, excluding the 'extended' parts
        var rect = UIEdgeInsetsInsetRect(tableView.frame, tableView.contentInset)
        rect = tableView.convert(rect, from: superview)
        guard let visibleIndexPaths = tableView.indexPathsForRows(in: rect) else {
            return nil
        }
        
        //Filter indexPaths that have a row of 0
        let firstRows = visibleIndexPaths.filter { (indexPath) -> Bool in
            return indexPath.row == 0
        }
        //If we have a row starting with 0, return that first. Else return the last found indexPath
        if firstRows.count > 0 {
            return firstRows.first?.section
        } else {
            return visibleIndexPaths.last?.section
        }
    }
    
    func scrollToNextCommentThread() {
        guard let currentThread = self.currentThread, let tableView = self.tableView else {
            return
        }
        let nextSection: Int = currentThread + 1
        if nextSection < tableView.numberOfSections && tableView.numberOfRows(inSection: nextSection) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: nextSection), at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
}
