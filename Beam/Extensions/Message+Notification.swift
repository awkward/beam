//
//  Message+Notification.swift
//  Beam
//
//  Created by Rens Verhoeven on 15-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import Snoo
import UserNotifications

extension Message {

    func notificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default()
        
        var userInfo = [String: Any]()
        var messageInfo = [String: Any]()
        if self.reference != nil {
            //Notification
            content.title = self.author ?? (self.subject?.capitalized(with: NSLocale.current) ?? AWKLocalizedString("notif-tit-new-notification"))
            content.body = "\(self.postTitle ?? "Post")\n\(self.content!)"
            
        } else {
            //Messages
            content.title = self.author ?? "reddit"
            content.body = "\(self.subject ?? "Message")\n\(self.content!)"
            
            if self.author ?? "reddit" != "reddit" {
                //Only if the message is not from "reddit" they can be replies
                content.categoryIdentifier = "reddit_message"
            }
        }
        messageInfo[UserNotificationCustomBodyKeys.Action.rawValue] = UserNotificationActionKey.ShowMessage.rawValue
        messageInfo[UserNotificationCustomBodyKeys.Object.rawValue] = self.redditDictionaryRepresentation()
        
        userInfo[UserNotificationCustomBodyKey] = messageInfo
        
        content.userInfo = userInfo
        
        return content
    }
    
}
