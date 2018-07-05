//
//  NSDate+RelativeFormatter.swift
//  beam
//
//  Created by Robin Speijer on 29-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

extension Date {
    
    private static let sharedRelativeDateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.short
        formatter.timeStyle = DateFormatter.Style.none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    var localizedRelativeTimeString: String? {

        let calendarComponents: [Calendar.Component] = [Calendar.Component.second, Calendar.Component.minute, Calendar.Component.hour, Calendar.Component.day]
        
        let components: DateComponents = Calendar.current.dateComponents(Set(calendarComponents), from: self, to: Date())
        var timeText: String = ""
        
        if components.day! > 9 {
            //We continue using text
        } else if let day = components.day, day >= 1 {
            timeText = "\(day)" + NSLocalizedString("time-day-short", comment: "Day abbreviation (eg. for 1d ago)")
        } else if let hour = components.hour, hour >= 1 {
            timeText = "\(hour)" + NSLocalizedString("time-hour-short", comment: "Hour abbreviation (eg. for 1h ago)")
        } else if let minute = components.minute, minute >= 1 {
            timeText = "\(minute)" + NSLocalizedString("time-minute-short", comment: "Minute abbreviation (eg. for 1m ago)")
        } else if let second = components.second, second >= 1 {
            timeText = "\(second)" + NSLocalizedString("time-second-short", comment: "Second abbreviation (eg. for 1s ago)")
        }
        
        if timeText.count <= 0 {
            timeText = Date.sharedRelativeDateFormatter.string(from: self)
        }
        
        return timeText

    }
    
}
