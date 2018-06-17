//
//  ReportViewController.swift
//  beam
//
//  Created by Rens Verhoeven on 26-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CherryKit

final class ReportViewController: BeamTableViewController {
    
    var post: Post?
    var activity: ReportPostActivity?
    @IBOutlet var reportButton: UIBarButtonItem!
    
    var selectedReason: PostReportReason = .Other

    @IBAction func report(_ sender: AnyObject?) {
        if let post = self.post {
            if let accessToken = AppDelegate.shared.cherryController.accessToken, let objectName = self.post?.objectName {
                let reason = self.selectedReason.rawValue
                let task = ReportTask(token: accessToken, reason: reason, objectName: objectName)
                task.start({ (result) -> Void in
                    if let error = result.error {
                        AWKDebugLog("Error reporting post: \(error)")
                    }
                })
            }
            post.isHidden = true
            NotificationCenter.default.post(name: .PostDidChangeHiddenState, object: post)
            let reportOperation = post.reportOperation(self.selectedReason, otherReason: nil, authenticationController: AppDelegate.shared.authenticationController)
            let hideOperation = post.markHiddenOperation(true, authenticationController: AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([reportOperation, hideOperation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
                if let error = error {
                    AWKDebugLog("Error reporting post: \(error)")
                }
            })
        }
        self.closeActivity(true)
    }
    
    @IBAction func cancel(_ sender: AnyObject?) {
        self.closeActivity(false)
    }
    
    fileprivate func closeActivity(_ completed: Bool) {
        if let activity = self.activity {
            activity.activityDidFinish(completed)
        }
        self.dismiss(animated: true) { () -> Void in
            if completed {
                DispatchQueue.main.async(execute: { () -> Void in
                    let alertController = BeamAlertController(title: AWKLocalizedString("post-reported"), message: AWKLocalizedString("post-reported-message"), preferredStyle: .alert)
                    alertController.addCloseAction()
                    AppDelegate.topViewController()?.present(alertController, animated: true, completion: nil)
                })
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
        switch (indexPath as IndexPath).row {
        case 0:
            self.selectedReason = .Spam
        case 1:
            self.selectedReason = .VoteManipulation
        case 2:
            self.selectedReason = .PersonalInformation
        case 3:
            self.selectedReason = .SexualizingMinors
        case 4:
            self.selectedReason = .BreakingReddit
        default:
            self.selectedReason = .Other
        }
        self.reloadReportButton()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
        self.reloadReportButton()
    }
    
    func reloadReportButton() {
        if self.tableView.indexPathForSelectedRow != nil {
            self.reportButton.isEnabled = true
        } else {
            self.reportButton.isEnabled = false
        }
    }
}
