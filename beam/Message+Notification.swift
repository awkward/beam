
//
//  Message+Notification.swift
//  Beam
//
//  Created by Rens Verhoeven on 15-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import Snoo

extension Message {

    func localNotification() -> UILocalNotification {
        let notification = UILocalNotification()
        var userInfo = [String : Any]()
        var messageInfo = [String : Any]()
        if self.reference != nil {
            //Notification
            notification.alertTitle = self.author ?? (self.subject?.capitalized(with: NSLocale.current) ?? AWKLocalizedString("notif-tit-new-notification"))
            notification.alertBody = "\(self.postTitle ?? "Post")\n\(self.content!)"
            
        } else {
            //Messages
            notification.alertTitle = self.author ?? "reddit"
            notification.alertBody = "\(self.subject ?? "Message")\n\(self.content!)"
            
            if self.author ?? "reddit" != "reddit" {
                //Only if the message is not from "reddit" they can be replies
                notification.category = "reddit_message"
            }
            
        }
        messageInfo[UserNotificationCustomBodyKeys.Action.rawValue] = UserNotificationActionKey.ShowMessage.rawValue
        
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.fireDate = NSDate() as Date
        
        messageInfo[UserNotificationCustomBodyKeys.Object.rawValue] = self.redditDictionaryRepresentation()
        
        userInfo[UserNotificationCustomBodyKey] = messageInfo
        
        notification.userInfo = userInfo
        return notification
    }
    
}
