//
//  TouchesForwardingView.swift
//  Beam
//
//  Created by Rens Verhoeven on 26/10/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit

/// This view can be added to a view to forward touches that are normally outside of the view to a specified receiving view
/// For insstance, a UITableView that is only have of the screens size, can add this view below it and set the receivingView to the tableView.
/// This will cause all the touches outside of the UITableView to be forwarded to the UITableView. Allow for using the scroll gesture outside of the tableView
class TouchesForwardingView: UIView {

    /// The view that should receive the touches that the TouchesForwardingView gets
    @IBOutlet var receivingView: UIView?
    
    init(receivingView: UIView) {
        self.receivingView = receivingView
        super.init(frame: CGRect())
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self.receivingView
    }

}
