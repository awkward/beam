//
//  UISearchBar+Background.swift
//  Beam
//
//  Created by Rens Verhoeven on 26-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit

extension UISearchBar {
    
    fileprivate func applyBeamStyle() {
        let searchTextField = self.privateViewsOfType(UITextField.self).first
        self.tintColor = AppearanceValue(light: UIColor.white, dark: UIColor.beamPurpleLight)
        searchTextField?.tintColor = AppearanceValue(light: UIColor.beamPurple, dark: UIColor.beamPurpleLight)
        self.textColor = AppearanceValue(light: UIColor.black, dark: UIColor.white)
        
        var placeholderText: String! = self.placeholder
        if self.placeholder == nil {
            placeholderText = searchTextField?.attributedPlaceholder?.string ?? "Search"
        }
        let placeholderColor = AppearanceValue(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.5)
        searchTextField?.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
        
        self.setImage(UISearchBar.searchIconWithColor(placeholderColor), for: .search, state: UIControl.State())
        self.searchTextPositionAdjustment = UIOffset(horizontal: 8, vertical: 0)
        
        self.keyboardAppearance = AppearanceValue(light: UIKeyboardAppearance.default, dark: UIKeyboardAppearance.dark)
    }
    
    func applyBeamBarStyle() {
        self.applyBeamStyle()
        
        self.tintColor = AppearanceValue(light: UIColor.beamPurple, dark: UIColor.beamPurpleLight)
        
        let searchFieldBackgroundImage = UISearchBar.searchFieldBackgroundImageWithBackgroundColor(AppearanceValue(light: .systemGroupedBackground, dark: UIColor.white.withAlphaComponent(0.1)))
        self.setSearchFieldBackgroundImage(searchFieldBackgroundImage, for: UIControl.State())
        
        let searchBarBackgroundImage = UISearchBar.searchBarBackgroundImageWithBackgroundColor(AppearanceValue(light: UIColor.white, dark: UIColor.beamDarkContentBackground), seperatorColor: AppearanceValue(light: UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), dark: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1)))
        self.setBackgroundImage(searchBarBackgroundImage, for: .any, barMetrics: .default)
    }
    
    func applyBeamBarStyleWithoutBorder() {
        self.applyBeamBarStyle()
        
        let searchBarBackgroundImage = UISearchBar.searchBarBackgroundImageWithBackgroundColor(AppearanceValue(light: UIColor.white, dark: UIColor.beamDarkContentBackground), seperatorColor: nil)
        self.setBackgroundImage(searchBarBackgroundImage, for: .any, barMetrics: .default)
        
        let scopeBarBackgroundImage = UISearchBar.searchBarBackgroundImageWithBackgroundColor(AppearanceValue(light: UIColor.white, dark: UIColor.beamDarkContentBackground), seperatorColor: AppearanceValue(light: UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), dark: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1)))
        self.scopeBarBackgroundImage = scopeBarBackgroundImage
    }
    
    func applyBeamGrayBarStyle() {
        self.applyBeamStyle()
        
        self.tintColor = AppearanceValue(light: UIColor.beamPurple, dark: UIColor.beamPurpleLight)
        
        if traitCollection.userInterfaceStyle == .dark {
            let searchFieldBackgroundImage = UISearchBar.searchFieldBackgroundImageWithBackgroundColor(UIColor.white.withAlphaComponent(0.1))
            self.setSearchFieldBackgroundImage(searchFieldBackgroundImage, for: UIControl.State())
            
            let searchBarBackgroundImage = UISearchBar.searchBarBackgroundImageWithBackgroundColor(UIColor.beamDarkContentBackground, seperatorColor: UIColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1))
            self.setBackgroundImage(searchBarBackgroundImage, for: .any, barMetrics: .default)
            self.scopeBarBackgroundImage = searchBarBackgroundImage
        } else {
            self.setSearchFieldBackgroundImage(nil, for: UIControl.State())
            self.setBackgroundImage(nil, for: .any, barMetrics: .default)
        }
        
    }
    
    func applyBeamNavigationBarStyle() {
        self.applyBeamStyle()
        let searchFieldBackgroundImage = UISearchBar.searchFieldBackgroundImageWithBackgroundColor(AppearanceValue(light: UIColor.white, dark: UIColor.white.withAlphaComponent(0.1)))
        self.setSearchFieldBackgroundImage(searchFieldBackgroundImage, for: UIControl.State())
    }
    
    class func searchFieldBackgroundImageWithBackgroundColor(_ backgroundColor: UIColor = UIColor.white) -> UIImage? {
        let cornerRadius: CGFloat = 5
        let width: CGFloat = (cornerRadius * 2) + 1
        let rect = CGRect(x: 0, y: 0, width: width, height: 30)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        backgroundColor.setFill()
        path.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: cornerRadius, bottom: 0, right: cornerRadius), resizingMode: .tile)
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func searchBarBackgroundImageWithBackgroundColor(_ backgroundColor: UIColor = UIColor.white, seperatorColor: UIColor? = nil) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 3, height: 3)
        let path = UIBezierPath(rect: rect)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        backgroundColor.setFill()
        path.fill()
        
        if let seperatorColor = seperatorColor {
            let seperatorHeight = 1 / UIScreen.main.scale
            let seperatorRect = CGRect(x: 0, y: rect.height - seperatorHeight, width: rect.width, height: seperatorHeight)
            let seperatorPath = UIBezierPath(rect: seperatorRect)
            seperatorColor.setFill()
            seperatorPath.fill()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1), resizingMode: .tile)
        UIGraphicsEndImageContext()
        
        return image
    }
    
    class func searchIconWithColor(_ tintColor: UIColor = UIColor.black.withAlphaComponent(0.5)) -> UIImage? {
        let icon = UIImage(named: "search_icon")!
        let rect = CGRect(origin: CGPoint(), size: icon.size)
        
        UIGraphicsBeginImageContextWithOptions (rect.size, false, 0)
        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        //Flip the image for proper placement
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        //Draw a square with the tintColor
        context.setBlendMode(CGBlendMode.normal)
        tintColor.setFill()
        context.fill(rect)
        
        //Remove the portion of the square that is not the icon image
        context.setBlendMode(CGBlendMode.destinationIn)
        context.draw(icon.cgImage!, in: rect)
        
        let tintedImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return tintedImage
    }
}
