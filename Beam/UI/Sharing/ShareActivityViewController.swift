//
//  ShareActivityViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 11/10/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

class ShareActivityViewController: UIActivityViewController {

    var shareItemProvider: URLShareItemProvider
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    private func setupView() {
        //Set the share tintColor on iOS 9 (UIAppearance doesn't always work)
        self.view.tintColor = UIColor.beamColor()
    }
    
    init(object: SyncObject) {
        let urlProvider = URLShareItemProvider(object: object)
        self.shareItemProvider = urlProvider
        var applicationActivities = [UIActivity]()
        applicationActivities.append(OpenInSafariActivity())
        if object is Post {
            applicationActivities.append(contentsOf: [ReportPostActivity(), HidePostActivity(), UnhidePostActivity(), DeletePostActivity(), EditPostActivity(), SavePostActivity(), UnsavePostActivity()])
        } else if object is Comment {
            applicationActivities.append(contentsOf: [CopyLinkActivity(), EditCommentActivity(), CopyCommentActivity(), SaveCommentActivity(), UnsaveCommentActivity(), DeleteCommentActivity()])
        }
        
        super.init(activityItems: [urlProvider, object], applicationActivities: applicationActivities)
    }

}
