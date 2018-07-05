//
//  LocalizableStrings.swift
//  beam
//
//  Created by Rens Verhoeven on 21-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

func AWKLocalizedString(_ key: String) -> String {
    assert(!key.contains(" "), "A key for a localized string is not allowed to contain spaces")
    return NSLocalizedString(key, comment: "")
}
