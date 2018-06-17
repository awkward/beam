//
//  FontSizeController.swift
//  beam
//
//  Created by Rens Verhoeven on 07-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

extension Notification.Name {
    
    public static let FontSizeCategoryDidChange = Notification.Name(rawValue: "FontSizeCategoryDidChangeNotification")
    
}

/// Handles font size changes done in the app or in the system. Use FontSizeController.category to get the font size category.
/// Some class funcs will help with adjusting the lineheight and text size
class FontSizeController: NSObject {
    
    @nonobjc static let FontSizeCategoryDefaultsKey = "font-size-override"
    
    //If this category is nil, you should use the default system content size using UIApplication.shared.preferredContentSizeCategory
    static var category: String? {
        set {
            let currentCategory: String? = UserDefaults.standard.string(forKey: FontSizeController.FontSizeCategoryDefaultsKey)
            if currentCategory != newValue {
                if newValue == nil {
                    UserDefaults.standard.removeObject(forKey: FontSizeController.FontSizeCategoryDefaultsKey)
                } else {
                    UserDefaults.standard.set(newValue, forKey: FontSizeController.FontSizeCategoryDefaultsKey)
                }
                NotificationCenter.default.post(name: .FontSizeCategoryDidChange, object: nil)
            }
        }
        get {
            return UserDefaults.standard.string(forKey: FontSizeController.FontSizeCategoryDefaultsKey)
        }

    }

    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(FontSizeController.contentSizeCategoryDidChange(_:)), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Display title
    
    class func displayTitle(forFontSizeCategory category: String?) -> String {
        let titles: [String: String] = [
            UIContentSizeCategory.extraSmall.rawValue: NSLocalizedString("extra-small-font-size-option", comment: "Font size is extra small"),
            UIContentSizeCategory.small.rawValue: NSLocalizedString("small-font-size-option", comment: "Font size that is small"),
            UIContentSizeCategory.medium.rawValue: NSLocalizedString("medium-font-size-option", comment: "Font size that is medium"),
            UIContentSizeCategory.large.rawValue: NSLocalizedString("large-font-size-option", comment: "Font size that is large (default)"), //Default!
            UIContentSizeCategory.extraLarge.rawValue: NSLocalizedString("extra-large-font-size-option", comment: "Font size that is extra large"),
            UIContentSizeCategory.extraExtraLarge.rawValue: NSLocalizedString("extra-extra-large-font-size-option", comment: "Font size that is extra extra large"),
            UIContentSizeCategory.extraExtraExtraLarge.rawValue: NSLocalizedString("extra-extra-extra-large-font-size-option", comment: "Font size that is extra extra extra large ")
        ]
        if let category = category, let title = titles[category] {
            return title
        }
        return NSLocalizedString("system-font-size-option", comment: "Font size that follows the system font size")
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func contentSizeCategoryDidChange(_ notification: Notification) {
        if FontSizeController.category == nil {
            NotificationCenter.default.post(name: .FontSizeCategoryDidChange, object: nil)
        }
    }
    
    // MARK: - Font size information (adjustments, sizes etc)
    
    private static let lineHeightAdjustments: [String: CGFloat] = [
        UIContentSizeCategory.extraSmall.rawValue: -3,
        UIContentSizeCategory.small.rawValue: -2,
        UIContentSizeCategory.medium.rawValue: -1,
        UIContentSizeCategory.large.rawValue: 0, //Default!
        UIContentSizeCategory.extraLarge.rawValue: 1,
        UIContentSizeCategory.extraExtraLarge.rawValue: 2,
        UIContentSizeCategory.extraExtraExtraLarge.rawValue: 3,
        UIContentSizeCategory.accessibilityMedium.rawValue: 4, //Same as Extra Extra Extra Large
        UIContentSizeCategory.accessibilityLarge.rawValue: 5,
        UIContentSizeCategory.accessibilityExtraLarge.rawValue: 6,
        UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue: 7
    ]
    
    private static let fontSizeAdjustments: [String: CGFloat] = [
        UIContentSizeCategory.extraSmall.rawValue: -3,
        UIContentSizeCategory.small.rawValue: -2,
        UIContentSizeCategory.medium.rawValue: -1,
        UIContentSizeCategory.large.rawValue: 0, //Default!
        UIContentSizeCategory.extraLarge.rawValue: 1,
        UIContentSizeCategory.extraExtraLarge.rawValue: 2,
        UIContentSizeCategory.extraExtraExtraLarge.rawValue: 3,
        UIContentSizeCategory.accessibilityMedium.rawValue: 4, //Same as Extra Extra Extra Large
        UIContentSizeCategory.accessibilityLarge.rawValue: 5,
        UIContentSizeCategory.accessibilityExtraLarge.rawValue: 6,
        UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue: 7
    ]
    
    // MARK: - Font size adjusting methods
    
    class func adjustedLineHeight(_ lineHeight: CGFloat, forContentSizeCategory category: String? = nil) -> CGFloat {
        var contentSizeCategory = UIApplication.shared.preferredContentSizeCategory.rawValue
        if let category: String = UserDefaults.standard.string(forKey: FontSizeController.FontSizeCategoryDefaultsKey) {
            contentSizeCategory = category
        }
        if let category = category {
            contentSizeCategory = category
        }
        
        var adjustment: CGFloat = 0
        if let newAdjustement = self.lineHeightAdjustments[contentSizeCategory] {
            adjustment = newAdjustement
        }
        
        var newLineHeight: CGFloat = lineHeight + adjustment
        if newLineHeight < 12 {
            newLineHeight = 12
        }
        return newLineHeight
    }
    
    class func adjustedFontSize(_ fontSize: CGFloat, forContentSizeCategory category: String? = nil) -> CGFloat {
        var contentSizeCategory = UIApplication.shared.preferredContentSizeCategory.rawValue
        if let category: String = UserDefaults.standard.string(forKey: FontSizeController.FontSizeCategoryDefaultsKey) {
            contentSizeCategory = category
        }
        if let category: String = category {
            contentSizeCategory = category
        }
        
        var adjustment: CGFloat = 0
        if let newAdjustement = self.fontSizeAdjustments[contentSizeCategory] {
            adjustment = newAdjustement
        }
        
        var newLineHeight: CGFloat = fontSize + adjustment
        if newLineHeight < 12 {
            newLineHeight = 12
        }
        return newLineHeight
    }
    
}
