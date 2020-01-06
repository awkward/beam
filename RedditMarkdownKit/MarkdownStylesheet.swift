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
    fileprivate (set) public var attributes: [MarkdownElementType: [NSAttributedString.Key: Any]]
    
    /// Markdown element types that should be ignored (or handled like paragraph text).
    public var elementTypeExclusions: [MarkdownElementType]?
    
    /// Initializes a new MarkdownStylesheet from the given text attributes, grouped by Markdown element types. You could also use the systemStylesheet static method for convenience.
    public init(attributes: [MarkdownElementType: [NSAttributedString.Key: Any]]) {
        self.attributes = attributes
    }
    
    /// A MarkdownStylesheet based on iOS preferred fonts
    public static func systemStylesheet() -> MarkdownStylesheet {
        let baseFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        return MarkdownStylesheet.systemStylesheetWithBaseFont(baseFont)
    }
    
    public static func systemStylesheetWithBaseFont(_ baseFont: UIFont) -> MarkdownStylesheet {
        
        let baseFontDescriptor: UIFontDescriptor = baseFont.fontDescriptor
        let baseFontBoldDescriptor: UIFontDescriptor? = baseFontDescriptor.withSymbolicTraits([UIFontDescriptor.SymbolicTraits.traitBold])
        
        var attributes: [MarkdownElementType: [NSAttributedString.Key: AnyObject]] = [MarkdownElementType: [NSAttributedString.Key: AnyObject]]()
        attributes[MarkdownElementType.paragraph] = [NSAttributedString.Key.font: baseFont]
        attributes[MarkdownElementType.unorderedListElement] = [NSAttributedString.Key.font: baseFont]
        attributes[MarkdownElementType.boldItalic] = [NSAttributedString.Key.font: UIFont(descriptor: baseFontDescriptor.withSymbolicTraits([UIFontDescriptor.SymbolicTraits.traitBold, UIFontDescriptor.SymbolicTraits.traitItalic])!, size: baseFont.pointSize)]
        if let fontDescriptor = baseFontDescriptor.withSymbolicTraits([UIFontDescriptor.SymbolicTraits.traitBold]) {
            attributes[MarkdownElementType.bold] = [NSAttributedString.Key.font: UIFont(descriptor: fontDescriptor, size: baseFont.pointSize)]
        } else {
            attributes[MarkdownElementType.bold] = [NSAttributedString.Key.font: UIFont(descriptor: baseFontDescriptor, size: baseFont.pointSize)]
        }
        
        if let fontDescriptor = baseFontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits.traitItalic) {
            attributes[MarkdownElementType.italic] = [NSAttributedString.Key.font: UIFont(descriptor: fontDescriptor, size: baseFont.pointSize)]
        } else {
            attributes[MarkdownElementType.italic] = [NSAttributedString.Key.font: UIFont(descriptor: baseFontDescriptor, size: baseFont.pointSize)]
        }
        attributes[MarkdownElementType.strikethrough] = [NSAttributedString.Key.strikethroughStyle: NSNumber(value: NSUnderlineStyle.single.rawValue as Int), NSAttributedString.Key.font: baseFont]
        //attributes[MarkdownElementType.superscript] = [kCTSuperscriptAttributeName as String: NSNumber(value: 1 as Int) as CFNumber]
        //TODO: Bring back superscript!
        attributes[MarkdownElementType.inlineCode] = [NSAttributedString.Key.font: UIFont(descriptor: baseFontDescriptor.withFamily("Courier"), size: baseFont.pointSize)]
        attributes[MarkdownElementType.code] = [NSAttributedString.Key.font: UIFont(descriptor: baseFontDescriptor.withFamily("Courier"), size: baseFont.pointSize)]
        
        let headingFontDescriptor: UIFontDescriptor = baseFontBoldDescriptor ?? baseFontDescriptor
        
        attributes[MarkdownElementType.h1] = [NSAttributedString.Key.font: UIFont(descriptor: headingFontDescriptor, size: headingFontDescriptor.pointSize + 3)]
        attributes[MarkdownElementType.h2] = [NSAttributedString.Key.font: UIFont(descriptor: headingFontDescriptor, size: headingFontDescriptor.pointSize + 2)]
        attributes[MarkdownElementType.h3] = [NSAttributedString.Key.font: UIFont(descriptor: headingFontDescriptor, size: headingFontDescriptor.pointSize + 1)]
        attributes[MarkdownElementType.h4] = [NSAttributedString.Key.font: UIFont(descriptor: headingFontDescriptor, size: headingFontDescriptor.pointSize)]
        attributes[MarkdownElementType.h5] = [NSAttributedString.Key.font: baseFont]
        
        let quoteParagraphStyle = NSMutableParagraphStyle()
        quoteParagraphStyle.paragraphSpacingBefore = 15
        quoteParagraphStyle.paragraphSpacing = 15
        quoteParagraphStyle.headIndent = 15
        
        if let fontDescriptor = baseFontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits.traitItalic) {
            attributes[MarkdownElementType.quote] = [NSAttributedString.Key.paragraphStyle: quoteParagraphStyle, NSAttributedString.Key.font: UIFont(descriptor: fontDescriptor, size: baseFont.pointSize)]
        } else {
           attributes[MarkdownElementType.quote] = [NSAttributedString.Key.paragraphStyle: quoteParagraphStyle, NSAttributedString.Key.font: UIFont(descriptor: baseFontDescriptor, size: baseFont.pointSize)]
        }
        
        return MarkdownStylesheet(attributes: attributes)
    }
    
    public static func systemStyleSheetWithTextColor(_ textColor: UIColor) -> MarkdownStylesheet {
        let stylesheet = MarkdownStylesheet.systemStylesheet()
        var attributes = stylesheet.attributes
        for element in attributes.keys {
            var elementAttributes = attributes[element]!
            elementAttributes[NSAttributedString.Key.foregroundColor] = textColor
            attributes[element] = elementAttributes
        }
        return MarkdownStylesheet(attributes: attributes)
    }

}
