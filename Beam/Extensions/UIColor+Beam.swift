//
//  BeamColor.swift
//  beam
//
//  Created by Robin Speijer on 22-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

extension UIColor {
    
    // MARK: - Purple
    
    static var beam: UIColor {
        UIColor(named: "beam")!
    }
    
    static var beamPurple: UIColor {
        UIColor(named: "purple")!
    }
    
    static var beamPurpleLight: UIColor {
        UIColor(named: "purple_light")!
    }
    
    // MARK: - Blue
    
    static var beamBlue: UIColor {
        UIColor(named: "blue")!
    }
    
    // MARK: - Red
    
    static var beamRed: UIColor {
        UIColor(named: "red")!
    }
    
    static var beamRedDarker: UIColor {
        UIColor(named: "red_darker")!
    }
    
    // MARK: - Yellow
    
    static var beamYellow: UIColor {
        UIColor(named: "yellow")!
    }
    
    // MARK: - Grey
    
    static var beamGreyExtraDark: UIColor {
        UIColor(named: "grey_extra_dark")!
    }
    
    static var beamGreyDark: UIColor {
        UIColor(named: "grey_dark")!
    }
    
    static var beamGrey: UIColor {
        UIColor(named: "grey")!
    }
    
    static var beamGreyLight: UIColor {
        UIColor(named: "grey_light")!
    }
    
    static var beamGreyLighter: UIColor {
        UIColor(named: "grey_lighter")!
    }
    
    static var beamGreyExtraLight: UIColor {
        UIColor(named: "grey_extra_light")!
    }
    
    static var beamGreyExtraExtraLight: UIColor {
        UIColor(named: "grey_extra_extra_light")!
    }
    
    static var beamSeparator: UIColor {
        beamGreyExtraLight
    }
    
    // MARK: - Dark style
    
    static var beamDarkBackground: UIColor {
        beamBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
    }
    
    static var beamDarkContentBackground: UIColor {
        beamContentBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
    }
    
    static var beamDarkTableViewSeperator: UIColor {
        beamTableViewSeperator.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
    }
    
    // MARK: - Functional colors
    
    static var beamContentBackground: UIColor {
        UIColor(named: "content_background")!
    }
    
    static var beamTableViewSeperator: UIColor {
        UIColor(named: "table_separator")!
    }
    
    static var beamTableSeparator: UIColor {
        beamGreyExtraExtraLight
    }
    
    static var beamBackground: UIColor {
        UIColor(named: "background")!
    }
    
    static var beamBar: UIColor {
        UIColor(named: "bar")!
    }
    
    static var beamColorizedBar: UIColor {
        UIColor(named: "colorized_bar")!
    }
    
    static var beamPlainSectionHeader: UIColor {
        UIColor(named: "plain_section_header")!
    }
    
    static var beamSearchBarBackground: UIColor {
        UIColor(named: "searchbar_background")!
    }
}
