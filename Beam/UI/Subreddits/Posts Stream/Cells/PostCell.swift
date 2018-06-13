//
//  PostCell.swift
//  beam
//
//  Created by Robin Speijer on 21-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation
import Snoo

protocol PostCell: class {
    
    var post: Post? { get set }
    
    var onDetailView: Bool { get set }
    
}

extension PostCell {
    
    var content: Content? {
        set {
            if let comment = newValue as? Comment {
                self.post = comment.post
            } else {
                self.post = newValue as? Post
            }
        }
        get {
            return self.post
        }
    }
}
