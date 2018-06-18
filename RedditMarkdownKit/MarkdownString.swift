//
//  MarkdownString.swift
//  beam
//
//  Created by Robin Speijer on 19-08-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

enum RedditLinkType {
    case subreddit
    case user
}

/// A string with mapped MarkDown elements in it. This can be converted to an NSAttributedString using a MarkdownStylesheet struct. The stylesheet will contain all the visual elements like fonts, colors, etc. This makes it possible to use an analyzed markdown string in multiple places in your app without reparsing for a different layout.
open class MarkdownString: NSObject, NSSecureCoding {
    
    static let BeamInternalURLScheme = "beamwtf"
    
    // MARK: - Properties
    
    /// The string where MarkDown elements are mapped onto.
    fileprivate (set) open var baseString: NSMutableString
    
    /// All markdown elements that exist in the baseString.
    fileprivate var elements: [MarkdownElement]
    
    /// A boolean to decide whether to
    open var autoDetectLinks: Bool {
        didSet {
            self.elements = [MarkdownElement]()
            self.parseElements()
        }
    }
    
    // MARK: - Lifecycle
    
    /// Initializes a MarkdownString based on the given String. The MarkdownString constructor will instantly analyze the contents for markdown elements, so be sure to initialize on a background queue whenever possible.
    public init(string: String, autoDetectLinks: Bool = true) {
        baseString = NSMutableString(string: string)
        self.elements = [MarkdownElement]()
        self.autoDetectLinks = autoDetectLinks
        super.init()
        self.parseElements()
    }
    
    override open var description: String {
        return baseString as String
    }
    
    // MARK: - NSSecureCoding
    
    public class var supportsSecureCoding: Bool {
        return true
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(baseString, forKey: "baseString")
        aCoder.encode(autoDetectLinks, forKey: "autodetectLinks")
        
        let codedElements = elements.map { (element: MarkdownElement) -> [NSString: AnyObject] in
            return element.encode(baseString: baseString)
        }
        aCoder.encode(codedElements as NSArray, forKey: "elements")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        if let baseString = aDecoder.decodeObject(of: NSMutableString.self, forKey: "baseString") {
            self.baseString = baseString
        } else {
            self.baseString = ""
        }
        self.autoDetectLinks = aDecoder.decodeBool(forKey: "autodetectLinks")
        self.elements = [MarkdownElement]()
        
        super.init()
        
        if let codedElements = aDecoder.decodeObject(of: NSArray.self, forKey: "elements") as? [[NSString: AnyObject]] {
            self.elements = codedElements.map({ (element: [NSString: AnyObject]) -> MarkdownElement in
                return MarkdownElement.decode(element, baseString: baseString)
            })
        }
        
    }
    
    // MARK: - Rendering
    
    /**
    Renders a MarkdownString into a concrete NSAttributedString, based on a predefined stylesheet. This stylesheet decides all text attributes like fonts, colors, etc.
    - parameter stylesheet: The stylesheet with concrete text attributes to use while rendering an NSAttributedString.
    - returns: A concrete NSAttributedString (conforming to the stylesheet) for displaying the markdown text.
    */
    open func attributedStringWithStylesheet(_ stylesheet: MarkdownStylesheet) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: baseString as String, attributes: stylesheet.attributes[MarkdownElementType.paragraph])
        
        for element in self.elements {
            var attributes = stylesheet.attributes[element.type]
            if let url = element.url {
                attributes?[NSAttributedStringKey.link] = url
            }
            
            if stylesheet.elementTypeExclusions?.contains(element.type) != true {
                if element.range.length <= baseString.length {
                    let lengthMinusLocation = baseString.length - element.range.location
                    var range = element.range
                    if range.location < 0 {
                        range.location = 0
                    }
                    if lengthMinusLocation < range.length {
                        range.length = lengthMinusLocation
                    }
                    attributedString.setAttributes(attributes, range: range)
                } else {
                    //assertionFailure("Markdown element contains out of bounds range, so ranges are out of sync.")
                }
            }
        }
        
        return attributedString
    }
    
    // MARK: - Parsing elements
    
    fileprivate class var markdownCharacters: CharacterSet {
        return CharacterSet(charactersIn: "#[(*_>\t~`^/")
    }
    
    fileprivate func parseElements() {
        if (baseString as NSString).rangeOfCharacter(from: MarkdownString.markdownCharacters).location != NSNotFound {
            self.parseLineElements()
            self.parseInlineElements()
            self.updateLineElements()
        } else if autoDetectLinks {
            self.elements += parseRawLinkElements()
        }
    }
    
    /// Replaces the given range within the basestring with the given String. This will also update all existing elements in the elements array.
    fileprivate func replaceRange(_ subRange: NSRange, with string: NSString?) -> NSRange {
        
        var newRange = subRange
        newRange.length = string?.length ?? 0
        let offset = subRange.length - (string?.length ?? 0)
        
        if let string = string {
            self.baseString.replaceCharacters(in: subRange, with: string as String)
        } else {
            self.baseString.deleteCharacters(in: subRange)
        }
        
        // Move elements that come after the replaced range
        elements = elements.map({ (element: MarkdownElement) -> MarkdownElement in
            if element.range.location > newRange.location {
                var newElement = element
                let startIndex = newElement.range.location - offset
                newElement.range = NSRange(location: startIndex, length: newElement.range.length)
                return newElement
            } else {
                return element
            }
        })
        
        return newRange
    }
    
    // MARK: Line elements
    
    fileprivate func parseLineElements() {
        var replacementOffset = 0
        
        for line in baseString.components(separatedBy: CharacterSet.newlines) {
            let trimmedLine = line.stringByTrimmingTrailingCharactersInSet(CharacterSet.whitespaces)
            
            var element: MarkdownElement?
            if let lineRange = parseLineOnlyElements(["*", "-"], inLine: trimmedLine) {
                element = MarkdownElement(range: lineRange, startIndexOffset: replacementOffset, type: MarkdownElementType.horizontalLine)
                replacementOffset -= lineRange.length - element!.range.length
            } else if let codeRange = parseLinePrefixElement("    ", inLine: trimmedLine) {
                element = MarkdownElement(range: codeRange, startIndexOffset: replacementOffset, type: MarkdownElementType.code)
                replacementOffset -= codeRange.length - element!.range.length
            } else if let underlineRange = parseLinePrefixElement("######", inLine: trimmedLine, trimWhitespace: true) {
                element = MarkdownElement(range: underlineRange, startIndexOffset: replacementOffset, type: MarkdownElementType.underline)
                replacementOffset -= underlineRange.length - element!.range.length
            } else if let h5Range = parseLinePrefixElement("#####", inLine: trimmedLine, trimWhitespace: true) {
                element = MarkdownElement(range: h5Range, startIndexOffset: replacementOffset, type: MarkdownElementType.h5)
                replacementOffset -= h5Range.length - element!.range.length
            } else if let h4Range = parseLinePrefixElement("####", inLine: trimmedLine, trimWhitespace: true) {
                element = MarkdownElement(range: h4Range, startIndexOffset: replacementOffset, type: MarkdownElementType.h4)
                replacementOffset -= h4Range.length - element!.range.length
            } else if let h3Range = parseLinePrefixElement("###", inLine: trimmedLine, trimWhitespace: true) {
                element = MarkdownElement(range: h3Range, startIndexOffset: replacementOffset, type: MarkdownElementType.h3)
                replacementOffset -= h3Range.length - element!.range.length
            } else if let h2Range = parseLinePrefixElement("##", inLine: trimmedLine, trimWhitespace: true) {
                element = MarkdownElement(range: h2Range, startIndexOffset: replacementOffset, type: MarkdownElementType.h2)
                replacementOffset -= h2Range.length - element!.range.length
            } else if let h1Range = parseLinePrefixElement("#", inLine: trimmedLine, trimWhitespace: true) {
                element = MarkdownElement(range: h1Range, startIndexOffset: replacementOffset, type: MarkdownElementType.h1)
                replacementOffset -= h1Range.length - element!.range.length
            } else if let quoteRange = parseLinePrefixElement(">", inLine: trimmedLine, trimWhitespace: true) {
                element = MarkdownElement(range: quoteRange, startIndexOffset: replacementOffset, type: MarkdownElementType.quote)
                replacementOffset -= quoteRange.length - element!.range.length
            } else if let quoteRange = parseLinePrefixElement("* ", inLine: trimmedLine, trimWhitespace: true, replacement: "• ") {
                element = MarkdownElement(range: quoteRange, startIndexOffset: replacementOffset, type: MarkdownElementType.unorderedListElement)
                replacementOffset -= quoteRange.length - element!.range.length
            } else if let quoteRange = parseLinePrefixElement("- ", inLine: trimmedLine, trimWhitespace: true, replacement: "• ") {
                element = MarkdownElement(range: quoteRange, startIndexOffset: replacementOffset, type: MarkdownElementType.unorderedListElement)
                replacementOffset -= quoteRange.length - element!.range.length
            }
            if element != nil {
                element!.isLineElement = true
                self.elements.append(element!)
            }
        }
        
    }
    
    fileprivate func parseLinePrefixElement(_ elementPrefix: NSString, inLine line: NSString, trimWhitespace: Bool = false, replacement: NSString? = nil) -> NSRange? {
        if line.hasPrefix(elementPrefix as String) {
            let lineRange = baseString.range(of: line as String)
            if lineRange.location != NSNotFound {
                if trimWhitespace {
                    var newString: NSString = line.substring(from: elementPrefix.length) as NSString
                    newString = newString.stringByTrimmingLeadingCharactersInSet(CharacterSet.whitespaces)
                    let lengthDifference = line.length - (newString as NSString).length
                    var removingRange = lineRange
                    removingRange.length = lengthDifference
                    
                    _ = replaceRange(removingRange, with: replacement)
                    let resultRange = NSRange(location: removingRange.location, length: (newString as NSString).length)
                    return resultRange
                } else {
                    return NSRange(location: lineRange.location - elementPrefix.length, length: lineRange.length - elementPrefix.length)
                }
            }
        }
        return nil
    }
    
    //Horizontal lines are line only elements, if the line only contains one of the characters, it will be parsed.
    fileprivate func parseLineOnlyElements(_ elements: [NSString], inLine line: NSString) -> NSRange? {
        var trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as NSString
        trimmedLine = trimmedLine.replacingOccurrences(of: " ", with: "") as NSString
        //Line only markdown is always at least 3 characters without spaces
        if trimmedLine.length < 3 {
            return nil
        }
        
        var hasFoundTheSameCharacters = false
        for element in elements {
            var sameCharacters = true
            let elementCharacter = element.substring(to: 1)
            let trimmedLineCharacters: NSMutableArray = NSMutableArray()
            for i in 0 ..< trimmedLine.length {
                let character = trimmedLine.substring(with: NSRange(location: i, length: 1))
                trimmedLineCharacters.add(character)
            }
            for character in trimmedLineCharacters {
                if !(character as AnyObject).isEqual(to: elementCharacter) {
                    sameCharacters = false
                    break
                }
            }
            if sameCharacters {
                hasFoundTheSameCharacters = true
                break
            }
        }
        if hasFoundTheSameCharacters {
            let lineRange = baseString.range(of: line as String)
            if  lineRange.location != NSNotFound {
                let resultRange = replaceRange(lineRange, with: nil)
                return resultRange
            }
        }
        return nil
    }
    
    // MARK: Inline elements
    
    fileprivate func parseInlineElements() {
        self.elements += parseLinkElements("(?:(?:\\s|^))((?:\\*\\*\\*|\\_\\_\\_)\\[([^\\]]*?)\\]\\s?\\(([^\\)]+?)\\)(?:\\*\\*\\*|\\_\\_\\_))(?:(?:\\s|$))", elementType: MarkdownElementType.boldItalic)
        self.elements += parseLinkElements("(?:(?:\\s|^))((?:\\*\\*|\\_\\_)\\[([^\\]]*?)\\]\\s?\\(([^\\)]+?)\\)(?:\\*\\*|\\_\\_))(?:(?:\\s|$))", elementType: MarkdownElementType.bold)
        self.elements += parseLinkElements("(?:(?:\\s|^))((?:\\*|\\_)\\[([^\\]]*?)\\]\\s?\\(([^\\)]+?)\\)(?:\\*|\\_))(?:(?:\\s|$))", elementType: MarkdownElementType.italic)
        self.elements += parseLinkElements("(?:(?:\\s|^))((?:\\~\\~)\\[([^\\]]*?)\\]\\s?\\(([^\\)]+?)\\)(?:\\~\\~))(?:(?:\\s|$))", elementType: MarkdownElementType.strikethrough)
        self.elements += parseLinkElements("(\\[([^\\]]*?)\\]\\s?\\(([^\\)]+?)\\))")
        
        if autoDetectLinks {
            self.elements += parseRawLinkElements()
        }
        
        self.elements += parseMarkupElements("(?:(?:\\s|^))((?:\\*\\*\\*|\\_\\_\\_)(.*?)(?:\\*\\*\\*|\\_\\_\\_))(?:(?:\\s|$))", type: MarkdownElementType.boldItalic)
        self.elements += parseMarkupElements("(?:(?:\\s|^))((?:\\*\\*|\\_\\_)(.*?)(?:\\*\\*|\\_\\_))(?:(?:\\s|$))", type: MarkdownElementType.bold)
        self.elements += parseMarkupElements("(?:(?:\\s|^))((?:\\*|\\_)(.*?)(?:\\*|\\_))(?:(?:\\s|$))", type: MarkdownElementType.italic)
        self.elements += parseMarkupElements("(`(.+?)`)", type: MarkdownElementType.inlineCode)
        self.elements += parseMarkupElements("((?:\\~\\~)(.*?)(?:\\~\\~))", type: MarkdownElementType.strikethrough)
        self.elements += parseMarkupElements("(\\^\\((.*?)\\))", type: MarkdownElementType.superscript)
        self.elements += parseMarkupElements("(\\^(.+?)\\b)", type: MarkdownElementType.superscript)
        
        self.elements += self.parseRedditLinkElements("(?:^|\\s)/?r/([a-z0-9_]{3,21})", linkType: RedditLinkType.subreddit)
        self.elements += self.parseRedditLinkElements("(?:^|\\s)/?u/([a-z0-9_]{3,21})", linkType: RedditLinkType.user)
    }
    
    fileprivate func parseRawLinkElements() -> [MarkdownElement] {
        do {
            let dataDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            return dataDetector.matches(in: baseString as String, options: [], range: NSRange(location: 0, length: self.baseString.length)).map({ (match: NSTextCheckingResult) -> MarkdownElement in
                var element = MarkdownElement(range: match.range, type: MarkdownElementType.paragraph)
                var urlString = baseString.substring(with: match.range)
                
                //This is a fix because dataDector does detect URL's with "www." as URL's, but doesn't transform them to "http://www."
                //NSURL or NSURLComponents can not be used to fix this, because that will break it even more
                if urlString.hasPrefix("http") == false && urlString.hasPrefix("www.") {
                    urlString = "http://" + urlString
                }
                
                element.url = URL(string: urlString)
                return element
            })
            
        } catch {
            NSLog("Error setting up link data detector in MarkdownString: %@", error as NSError)
        }
        
        return [MarkdownElement]()
    }
    
    fileprivate func elementsAtRange(_ range: NSRange) -> [MarkdownElement] {
        return self.elements.filter({ NSIntersectionRange(range, $0.range).length != 0 })
    }
    
    fileprivate func containsLinkAtRange(_ range: NSRange) -> Bool {
        return self.elementsAtRange(range).filter({ $0.url != nil  }).count > 0
    }
    
    fileprivate func isRelativeRedditLink(_ string: String) -> Bool {
        do {
            let regularExpression = try NSRegularExpression(pattern: "(?:^|\\s)/?r/([a-z0-9]{3,21})(?:/comments|/\\s|\\s)", options: [NSRegularExpression.Options.anchorsMatchLines, NSRegularExpression.Options.caseInsensitive])
            return regularExpression.matches(in: string, options: [], range: NSRange(location: 0, length: (string as NSString).length)).count > 0
        } catch {
            NSLog("Relative reddit link expression failed \(error)")
            return false
        }
    }
    
    fileprivate func parseLinkElements(_ pattern: String, elementType: MarkdownElementType = MarkdownElementType.paragraph) -> [MarkdownElement] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpression.Options.anchorsMatchLines, NSRegularExpression.Options.caseInsensitive])
            var elements = [MarkdownElement]()
            
            var lengthOffset = 0
            
            for match in regex.matches(in: baseString as String, options: [], range: NSRange(location: 0, length: self.baseString.length)) {

                if match.numberOfRanges == 4 {
                    let urlRange = match.range(at: 3).rangeWithLocationoffset(lengthOffset)
                    var urlString = baseString.substring(with: urlRange)
                    urlString = urlString.replacingOccurrences(of: " ", with: "%20")
                    var url = URL(string: urlString)
                    
                    if urlString.hasPrefix("/r/") && self.isRelativeRedditLink(urlString) {
                        
                        //It's a link to a subreddit, parse it like a subreddit
                        url = URL(string: "\(MarkdownString.BeamInternalURLScheme)://\(urlString)/")
                    }
                    
                    let elementRange = match.range(at: 1).rangeWithLocationoffset(lengthOffset)
                    let nameRange = match.range(at: 2).rangeWithLocationoffset(lengthOffset)
                    
                    lengthOffset -= (elementRange.length - nameRange.length)
                    
                    let resultRange = replaceRange(elementRange, with: baseString.substring(with: nameRange) as NSString)
                    
                    var element = MarkdownElement(range: resultRange, type: elementType)
                    element.url = url
                    elements.append(element)
                } else if match.numberOfRanges == 3 {
                    let urlRange = match.range(at: 2).rangeWithLocationoffset(lengthOffset)
                    let urlString = baseString.substring(with: urlRange)
                    if urlString.hasPrefix("#") {
                        //It's a flag link that only works on web, just remove it

                        let elementRange = match.range(at: 1).rangeWithLocationoffset(lengthOffset)
                        
                        lengthOffset -= elementRange.length
                        
                        _ = replaceRange(elementRange, with: nil)
                    }
                }
                
            }
            return elements
        } catch {
            NSLog("Could not parse link elements with pattern '%@': %@", pattern, error as NSError)
        }
        return [MarkdownElement]()
    }
    
    fileprivate func parseRedditLinkElements(_ pattern: String, linkType: RedditLinkType) -> [MarkdownElement] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpression.Options.anchorsMatchLines, NSRegularExpression.Options.caseInsensitive])
            let elements = regex.matches(in: baseString as String, options: [], range: NSRange(location: 0, length: self.baseString.length)).compactMap({ (match) -> MarkdownElement? in
                guard match.numberOfRanges == 2 else {
                    return nil
                }
                let elementRange = match.range(at: 0)
                let displayNameRange = match.range(at: 1)
                let displayName = self.baseString.substring(with: displayNameRange)
                
                let resultRange = replaceRange(elementRange, with: baseString.substring(with: elementRange) as NSString?)
                
                var element = MarkdownElement(range: resultRange, type: .paragraph)
                if linkType == RedditLinkType.subreddit {
                    element.url = URL(string: "\(MarkdownString.BeamInternalURLScheme)://subreddit/\(displayName)/")
                } else if linkType == RedditLinkType.user {
                    element.url = URL(string: "\(MarkdownString.BeamInternalURLScheme)://user/\(displayName)/")
                }
                
                return element
            })
            return elements
        } catch {
            NSLog("Could not parse link elements with pattern '%@': %@", pattern, error as NSError)
        }
        return [MarkdownElement]()
    }
    
    fileprivate func parseMarkupElements(_ pattern: String, type: MarkdownElementType) -> [MarkdownElement] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpression.Options.anchorsMatchLines])
            
            var lengthOffset = 0
            
            let elements = regex.matches(in: baseString as String, options: [], range: NSRange(location: 0, length: baseString.length)).compactMap({ (match) -> MarkdownElement? in
                guard match.numberOfRanges == 3 else {
                    return nil
                }
                let elementRange = match.range(at: 1).rangeWithLocationoffset(lengthOffset)
                let visibleRange = match.range(at: 2).rangeWithLocationoffset(lengthOffset)
                
                //Skip elements that have already been parsed to links
                guard !self.containsLinkAtRange(elementRange) else {
                    return nil
                }
                lengthOffset -= (elementRange.length - visibleRange.length)
                
                let resultRange = replaceRange(elementRange, with: baseString.substring(with: visibleRange) as NSString)
                
                return MarkdownElement(range: resultRange, type: type)
            })
            return elements
        } catch {
            NSLog("Could not parse markup elements with pattern '%@': %@", pattern, error as NSError)
        }
        return [MarkdownElement]()
    }
    
    fileprivate func updateLineElements() {
        for line in baseString.components(separatedBy: CharacterSet.newlines) {
            let lineString = line as NSString
            let range = self.baseString.range(of: line)
            let lineElements = self.elements.filter({ $0.range.location == range.location })
            for lineElement in lineElements {
                if let index = self.elements.index(of: lineElement), lineElement.range.length > lineString.length {
                    var newElement = MarkdownElement(range: NSRange(location: lineElement.range.location, length: lineString.length), startIndexOffset: 0, type: lineElement.type)
                    newElement.isLineElement = lineElement.isLineElement
                    newElement.url = lineElement.url
                    self.elements[index] = newElement
                }
            }
        }
    }
    
}
