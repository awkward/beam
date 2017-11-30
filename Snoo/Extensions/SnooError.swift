//
//  SnooError.swift
//  Snoo
//
//  Created by Robin Speijer on 14-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

public let SnooErrorDomain = "nl.madeawkward.snoo"

extension NSError {
    
    static func snooError(_ code: Int, localizedDescription: String?) -> NSError {
        if let localizedDescription = localizedDescription {
            return NSError(domain: SnooErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
        } else {
            return NSError(domain: SnooErrorDomain, code: code, userInfo: nil)
        }
    }
    
}
