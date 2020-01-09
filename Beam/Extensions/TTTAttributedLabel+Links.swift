//
//  TTTAttributedLabel+Links.swift
//  beam
//
//  Created by Rens Verhoeven on 20-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import TTTAttributedLabel

extension TTTAttributedLabel {
    
    class fileprivate func baseBeamLinkAttributes() -> [NSAttributedString.Key: Any] {
        let underlineStyle: NSUnderlineStyle = []
        return [.underlineStyle: NSNumber(value: underlineStyle.rawValue)]
    }
    
    class func beamLinkAttributesForMode(_ mode: DisplayMode) -> [NSAttributedString.Key: Any] {
        var linkAttributes = TTTAttributedLabel.baseBeamLinkAttributes()
        switch mode {
        case .dark:
            linkAttributes[NSAttributedString.Key.foregroundColor] = UIColor.beamPurpleLight()
        case .default:
            linkAttributes[NSAttributedString.Key.foregroundColor] = UIColor.beamColor()
        }
        return linkAttributes
    }
    
    class func beamActiveLinkAttributesForMode(_ mode: DisplayMode) -> [NSAttributedString.Key: Any] {
        var linkAttributes = TTTAttributedLabel.baseBeamLinkAttributes()
        switch mode {
        case .dark:
            linkAttributes[NSAttributedString.Key.foregroundColor] = UIColor.beamPurpleLight().withAlphaComponent(0.8)
        case .default:
            linkAttributes[NSAttributedString.Key.foregroundColor] = UIColor.beamColor().withAlphaComponent(0.8)
        }
        return linkAttributes
    }
    
    /// Returns links found in the label with the given scheme
    ///
    /// - Parameter schemes: The given schemes (in lowercase)
    /// - Returns: All the URLs found that match the schemes
    func linksWithSchemes(schemes: [String]) -> [URL] {
        let links = self.links.compactMap { (object) -> URL? in
            return (object as? NSTextCheckingResult)?.url
        }.filter { (url) -> Bool in
            guard let scheme = url.scheme?.lowercased() else {
                return false
            }
            return schemes.contains(scheme)
        }
        return links
    }
}
