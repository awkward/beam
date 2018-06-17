//
//  MarkdownElement.swift
//  beam
//
//  Created by Robin Speijer on 20-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

public enum MarkdownElementType: Int {
    case paragraph = 1
    case code
    case quote
    case h1
    case h2
    case h3
    case h4
    case h5
    case superscript
    case underline
    case strikethrough
    case inlineCode
    case italic
    case bold
    case boldItalic
    case horizontalLine
    case unorderedListElement
}

internal struct MarkdownElement: Equatable {
    
    var range: NSRange
    var type: MarkdownElementType
    var url: URL?
    var isLineElement: Bool?
    
    init(range: NSRange, startIndexOffset: Int = 0, type: MarkdownElementType) {
        let startIndex = range.location + startIndexOffset
        self.range = NSRange(location: startIndex, length: range.length)
        self.type = type
    }
    
    // MARK: - Encoding
    
    internal func encode(baseString: NSString) -> [NSString: AnyObject] {
        var dict = [NSString: AnyObject]()
        dict["start"] = NSNumber(value: range.location as Int)
        dict["count"] = NSNumber(value: range.length as Int)
        dict["type"] = NSNumber(value: type.rawValue as Int)
        if let url = url {
            dict["url"] = url as AnyObject?
        }
        if let lineElement = self.isLineElement {
            dict["line_element"] = lineElement as AnyObject?
        }
        return dict
    }
    
    internal static func decode(_ encodedElement: [NSString: AnyObject], baseString: NSString) -> MarkdownElement {
        let range = NSRange(location: (encodedElement["start"] as? NSNumber)?.intValue ?? 0, length: (encodedElement["count"] as? NSNumber)?.intValue ?? 0)
        let type = MarkdownElementType(rawValue: (encodedElement["type"] as? NSNumber)?.intValue ?? 1) ?? MarkdownElementType.paragraph
        var element = MarkdownElement(range: range, type: type)
        element.url = encodedElement["url"] as? URL
        element.isLineElement = encodedElement["line_element"] as? Bool
        return element
    }
    
}

func == (lhs: MarkdownElement, rhs: MarkdownElement) -> Bool {
    return lhs.range.location == rhs.range.location &&
        lhs.range.length == rhs.range.length &&
        lhs.type == rhs.type
}
