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
    
    class func beamLinkAttributesWithStyle(_ style: UIUserInterfaceStyle) -> [NSAttributedString.Key: Any] {
        var linkAttributes = TTTAttributedLabel.baseBeamLinkAttributes()
        switch style {
        case .dark:
            linkAttributes[NSAttributedString.Key.foregroundColor] = UIColor.beamPurpleLight
        default:
            linkAttributes[NSAttributedString.Key.foregroundColor] = UIColor.beam
        }
        return linkAttributes
    }
    
    class func beamActiveLinkAttributesWithStyle(_ style: UIUserInterfaceStyle) -> [NSAttributedString.Key: Any] {
        var linkAttributes = TTTAttributedLabel.baseBeamLinkAttributes()
        switch style {
        case .dark:
            linkAttributes[NSAttributedString.Key.foregroundColor] = UIColor.beamPurpleLight.withAlphaComponent(0.8)
        default:
            linkAttributes[NSAttributedString.Key.foregroundColor] = UIColor.beam.withAlphaComponent(0.8)
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
