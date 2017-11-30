//
//  MarkdownStylesheet.swift
//  beam
//
//  Created by Robin Speijer on 19-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

/// A stylesheet to be used for creating an NSAttributedString out of a MarkdownString.
public struct MarkdownStylesheet {
    
    /// The text attributes grouped by markdown elements.
    fileprivate (set) public var attributes: [MarkdownElementType: [String: Any]]
    
    /// Markdown element types that should be ignored (or handled like paragraph text).
    public var elementTypeExclusions: [MarkdownElementType]?
    
    /// Initializes a new MarkdownStylesheet from the given text attributes, grouped by Markdown element types. You could also use the systemStylesheet static method for convenience.
    public init(attributes: [MarkdownElementType: [String: Any]]) {
        self.attributes = attributes
    }
    
    /// A MarkdownStylesheet based on iOS preferred fonts
    public static func systemStylesheet() -> MarkdownStylesheet {
        let baseFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        return MarkdownStylesheet.systemStylesheetWithBaseFont(baseFont)
    }
    
    public static func systemStylesheetWithBaseFont(_ baseFont:UIFont) -> MarkdownStylesheet {
        
        let baseFontDescriptor: UIFontDescriptor = baseFont.fontDescriptor
        let baseFontBoldDescriptor: UIFontDescriptor? = baseFontDescriptor.withSymbolicTraits([UIFontDescriptorSymbolicTraits.traitBold])
        
        var attributes: [MarkdownElementType: [String: AnyObject]] = [MarkdownElementType: [String: AnyObject]]()
        attributes[MarkdownElementType.paragraph] = [NSFontAttributeName: baseFont]
        attributes[MarkdownElementType.unorderedListElement] = [NSFontAttributeName: baseFont]
        attributes[MarkdownElementType.boldItalic] = [NSFontAttributeName: UIFont(descriptor: baseFontDescriptor.withSymbolicTraits([UIFontDescriptorSymbolicTraits.traitBold, UIFontDescriptorSymbolicTraits.traitItalic])!, size: baseFont.pointSize)]
        if let fontDescriptor = baseFontDescriptor.withSymbolicTraits([UIFontDescriptorSymbolicTraits.traitBold]) {
            attributes[MarkdownElementType.bold] = [NSFontAttributeName: UIFont(descriptor: fontDescriptor, size: baseFont.pointSize)]
        } else {
            attributes[MarkdownElementType.bold] = [NSFontAttributeName: UIFont(descriptor: baseFontDescriptor, size: baseFont.pointSize)]
        }
        
        if let fontDescriptor = baseFontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits.traitItalic) {
            attributes[MarkdownElementType.italic] = [NSFontAttributeName: UIFont(descriptor: fontDescriptor, size: baseFont.pointSize)]
        } else {
            attributes[MarkdownElementType.italic] = [NSFontAttributeName: UIFont(descriptor: baseFontDescriptor, size: baseFont.pointSize)]
        }
        attributes[MarkdownElementType.strikethrough] = [NSStrikethroughStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue as Int), NSFontAttributeName: baseFont]
        attributes[MarkdownElementType.superscript] = [kCTSuperscriptAttributeName as String: NSNumber(value: 1 as Int) as CFNumber]
        attributes[MarkdownElementType.inlineCode] = [NSFontAttributeName: UIFont(descriptor: baseFontDescriptor.withFamily("Courier"), size: baseFont.pointSize)]
        attributes[MarkdownElementType.code] = [NSFontAttributeName: UIFont(descriptor: baseFontDescriptor.withFamily("Courier"), size: baseFont.pointSize)]
        
        
        let headingFontDescriptor: UIFontDescriptor = baseFontBoldDescriptor ?? baseFontDescriptor
        
        attributes[MarkdownElementType.h1] = [NSFontAttributeName: UIFont(descriptor: headingFontDescriptor, size: headingFontDescriptor.pointSize+3)]
        attributes[MarkdownElementType.h2] = [NSFontAttributeName: UIFont(descriptor: headingFontDescriptor, size: headingFontDescriptor.pointSize+2)]
        attributes[MarkdownElementType.h3] = [NSFontAttributeName: UIFont(descriptor: headingFontDescriptor, size: headingFontDescriptor.pointSize+1)]
        attributes[MarkdownElementType.h4] = [NSFontAttributeName: UIFont(descriptor: headingFontDescriptor, size: headingFontDescriptor.pointSize)]
        attributes[MarkdownElementType.h5] = [NSFontAttributeName: baseFont]
        
        let quoteParagraphStyle = NSMutableParagraphStyle()
        quoteParagraphStyle.paragraphSpacingBefore = 15
        quoteParagraphStyle.paragraphSpacing = 15
        quoteParagraphStyle.headIndent = 15
        
        if let fontDescriptor = baseFontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits.traitItalic) {
            attributes[MarkdownElementType.quote] = [NSParagraphStyleAttributeName: quoteParagraphStyle, NSFontAttributeName: UIFont(descriptor: fontDescriptor, size: baseFont.pointSize)]
        } else {
           attributes[MarkdownElementType.quote] = [NSParagraphStyleAttributeName: quoteParagraphStyle, NSFontAttributeName: UIFont(descriptor: baseFontDescriptor, size: baseFont.pointSize)]
        }
        
        return MarkdownStylesheet(attributes: attributes)
    }
    
    public static func systemStyleSheetWithTextColor(_ textColor:UIColor) -> MarkdownStylesheet {
        let stylesheet = MarkdownStylesheet.systemStylesheet()
        var attributes = stylesheet.attributes
        for element in attributes.keys {
            var elementAttributes = attributes[element]!
            elementAttributes[NSForegroundColorAttributeName] = textColor
            attributes[element] = elementAttributes
        }
        return MarkdownStylesheet(attributes: attributes)
    }

}
