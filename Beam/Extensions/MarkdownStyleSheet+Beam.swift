//
//  MarkdownStyleSheet+Beam.swift
//  beam
//
//  Created by Rens Verhoeven on 20-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import RedditMarkdownKit
import TTTAttributedLabel

extension MarkdownStylesheet {

    public static func beamStyleSheet(_ textStyle: UIFontTextStyle, darkmode: Bool = false) -> MarkdownStylesheet {
        let textColor = darkmode ? UIColor(red: 214 / 255, green: 214 / 255, blue: 214 / 255, alpha: 1) : UIColor(red: 65 / 255, green: 65 / 255, blue: 65 / 255, alpha: 1.00000)
        let headlineColor = textColor
        let baseFont: UIFont!
        if textStyle == .subheadline {
            let fontSize: CGFloat = FontSizeController.adjustedFontSize(15)
            baseFont = UIFont.systemFont(ofSize: fontSize)
        } else if textStyle == .footnote {
            let fontSize: CGFloat = FontSizeController.adjustedFontSize(13)
            baseFont = UIFont.systemFont(ofSize: fontSize)
        } else {
            baseFont = UIFont.preferredFont(forTextStyle: textStyle)
        }
        
        let stylesheet = MarkdownStylesheet.systemStylesheetWithBaseFont(baseFont)
        var attributes: [MarkdownElementType: [NSAttributedStringKey: Any]] = stylesheet.attributes
        
        let lineHeight: CGFloat? = ceil(baseFont.lineHeight)
        
        for element in attributes.keys {
            var elementAttributes: [NSAttributedStringKey: Any] = attributes[element]!
            
            //Adjust the colors
            if element == .h1 || element == .h2 || element == .h3 {
                elementAttributes[NSAttributedStringKey.foregroundColor] = headlineColor
            } else if element == .quote {
                elementAttributes[NSAttributedStringKey.foregroundColor] = textColor.withAlphaComponent(0.8)
            } else {
                elementAttributes[NSAttributedStringKey.foregroundColor] = textColor
            }
            
            //Add the custom striketrougk
            if element == .strikethrough {
                //elementAttributes[kTTTStrikeOutAttributeName] = true
                //TODO: Add strikethrough
            }
            
            if lineHeight != nil {
                //Adjust the paragraph style
                var paragraphStyle: NSMutableParagraphStyle!
                if let existingParagraphStyle = elementAttributes[NSAttributedStringKey.paragraphStyle] as? NSParagraphStyle {
                    paragraphStyle = existingParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
                } else {
                    paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                }
                paragraphStyle.minimumLineHeight = lineHeight!
                paragraphStyle.maximumLineHeight = lineHeight!
                
                elementAttributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
            }
            
            attributes[element] = elementAttributes
        }
        return MarkdownStylesheet(attributes: attributes)
    }

    public static func beamCommentsStyleSheet(_ darkmode: Bool = false) -> MarkdownStylesheet {
        let textColor = darkmode ? UIColor(red: 167 / 255, green: 167 / 255, blue: 167 / 255, alpha: 1) : UIColor(red: 65 / 255, green: 65 / 255, blue: 65 / 255, alpha: 1.00000)
        let headlineColor = textColor
         let fontSize: CGFloat = FontSizeController.adjustedFontSize(14)
        let baseFont = UIFont.systemFont(ofSize: fontSize)
        let stylesheet = MarkdownStylesheet.systemStylesheetWithBaseFont(baseFont)
        var attributes: [MarkdownElementType: [NSAttributedStringKey: Any]] = stylesheet.attributes
        
        let lineHeight: CGFloat? = FontSizeController.adjustedLineHeight(20)
        
        for element in attributes.keys {
            var elementAttributes: [NSAttributedStringKey: Any] = attributes[element]!
            
            //Adjust the colors
            if element == .h1 || element == .h2 || element == .h3 {
                elementAttributes[NSAttributedStringKey.foregroundColor] = headlineColor
            } else if element == .quote {
                elementAttributes[NSAttributedStringKey.foregroundColor] = textColor.withAlphaComponent(0.8)
            } else {
                elementAttributes[NSAttributedStringKey.foregroundColor] = textColor
            }
            
            //Add the custom striketrougk
            if element == .strikethrough {
                //elementAttributes[kTTTStrikeOutAttributeName] = true
                //TODO: Bring striketrhough back
            }
        
            if lineHeight != nil {
                //Adjust the paragraph style
                var paragraphStyle: NSMutableParagraphStyle!
                if let existingParagraphStyle = elementAttributes[NSAttributedStringKey.paragraphStyle] as? NSParagraphStyle {
                    paragraphStyle = existingParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
                } else {
                    paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                }
                paragraphStyle.minimumLineHeight = lineHeight!
                paragraphStyle.maximumLineHeight = lineHeight!
                
                elementAttributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
            }
            
            attributes[element] = elementAttributes
        }
        return MarkdownStylesheet(attributes: attributes)
    }
    
    public static func beamSelfPostStyleSheet(_ darkmode: Bool = false) -> MarkdownStylesheet {
        let textColor = darkmode ? UIColor(red: 214 / 255, green: 214 / 255, blue: 214 / 255, alpha: 1) : UIColor(red: 65 / 255, green: 65 / 255, blue: 65 / 255, alpha: 1.00000)
        let headlineColor = textColor
        let fontSize: CGFloat = FontSizeController.adjustedFontSize(14)
        let baseFont = UIFont.systemFont(ofSize: fontSize)
        let stylesheet = MarkdownStylesheet.systemStylesheetWithBaseFont(baseFont)
        var attributes = stylesheet.attributes
    
        let lineHeight: CGFloat? = FontSizeController.adjustedLineHeight(20)
        
        for element in attributes.keys {
            var elementAttributes = attributes[element]!
            
            //Adjust the colors
            if element == .h1 || element == .h2 || element == .h3 {
                elementAttributes[NSAttributedStringKey.foregroundColor] = headlineColor
            } else if element == .quote {
                elementAttributes[NSAttributedStringKey.foregroundColor] = textColor.withAlphaComponent(0.8)
            } else {
                elementAttributes[NSAttributedStringKey.foregroundColor] = textColor
            }
            
            //Add the custom striketrougk
            if element == .strikethrough {
                //elementAttributes[kTTTStrikeOutAttributeName] = true
                //TODO: Bring strikethrough back
            }
            
            if lineHeight != nil {
                //Adjust the paragraph style
                var paragraphStyle: NSMutableParagraphStyle!
                if let existingParagraphStyle = elementAttributes[NSAttributedStringKey.paragraphStyle] as? NSParagraphStyle {
                    paragraphStyle = existingParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
                } else {
                    paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                }
                paragraphStyle.minimumLineHeight = lineHeight!
                paragraphStyle.maximumLineHeight = lineHeight!
                
                elementAttributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
            }
            attributes[element] = elementAttributes
        }
        return MarkdownStylesheet(attributes: attributes)
    }
}
