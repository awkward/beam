//
//  NoticeHandling.swift
//  beam
//
//  Created by Rens Verhoeven on 21-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Foundation

protocol NoticeHandling {
    
    func handleError(_ error: NSError)
    func presentErrorMessage(_ message: String)
    func presentInformationMessage(_ message: String)
    func presentSuccessMessage(_ message: String)
}

extension NoticeHandling where Self: UIViewController {
    
    func handleError(_ error: NSError) {
        let message = error.localizedDescription
        self.presentErrorMessage(message)
    }
    
    func presentErrorMessage(_ message: String) {
        self.presentNoticeNotificationViewWithMessage(message, type: .error)
    }
    
    func presentInformationMessage(_ message: String) {
        self.presentNoticeNotificationViewWithMessage(message, type: .information)
    }
    
    func presentSuccessMessage(_ message: String) {
        self.presentNoticeNotificationViewWithMessage(message, type: .success)
    }
    
    fileprivate func presentNoticeNotificationViewWithMessage(_ message: String, type: NoticeNotificationViewType) {
        let noticeView = NoticeNotificationView(message: message, type: type)
        self.navigationController?.presentNoticeNotificationView(noticeView)
    }
    
}
