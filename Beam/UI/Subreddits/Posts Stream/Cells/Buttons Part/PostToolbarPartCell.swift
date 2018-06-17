//
//  PostToolbarPartCell.swift
//  beam
//
//  Created by Robin Speijer on 21-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

final class PostToolbarPartCell: BeamTableViewCell, PostCell {
   
    @IBOutlet weak var toolbarView: PostToolbarView!
    
    weak var post: Post? {
        didSet {
            self.toolbarView.post = self.post
        }
    }
    
    var onDetailView: Bool = false
    
    var showTopSeperator: Bool {
        get {
            return self.toolbarView.shouldShowSeperator
        }
        set {
            self.toolbarView.shouldShowSeperator = newValue
        }
    }
    
    // MARK: - Layout
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        NotificationCenter.default.addObserver(self, selector: #selector(PostToolbarPartCell.objectDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func objectDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            if let updatedObjects = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? NSSet, let post = self.post, updatedObjects.contains(post) {
                self.toolbarView.post = self.post
            }
        }
        
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 44)
    }
    
}
