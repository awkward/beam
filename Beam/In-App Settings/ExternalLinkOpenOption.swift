//
//  ExternalLinkOpenOption.swift
//  Beam
//
//  Created by Rens Verhoeven on 08/02/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

public enum ExternalLinkOpenOption: String {
    case inApp = "in-app"
    case safari = "safari"
    case chrome = "chrome"
    case onePassword = "one-password"
    case youTube = "youtube"
    case proTube = "protube"
    
    /// Returns if the app is available and installed for opening HTTP or HTTPS urls
    public var isAvailableForExternalLinks: Bool {
        switch self {
        case .inApp:
            return true
        case .safari:
            return UIApplication.shared.canOpenURL(URL(string: "https:")!)
        case .chrome:
            return UIApplication.shared.canOpenURL(URL(string: "googlechrome::")!)
        case .onePassword:
            return UIApplication.shared.canOpenURL(URL(string: "onepassword://search")!)
        default:
            return false
        }
    }
    
    /// Returns if the app is available and installed for opening youtube.com urls
    public var isAvailableForYouTubeLinks: Bool {
        switch self {
        case .inApp:
            return true
        case .youTube:
            return UIApplication.shared.canOpenURL(URL(string: "youtube:")!)
        case .proTube:
            return UIApplication.shared.canOpenURL(URL(string: "protube:")!)
        default:
            return false
        }
    }
    
    /// Returns an array (in order) of available options for opening links
    ///
    /// - Returns: All options that are available for opening links
    static func availableOptionsForLinks() -> [ExternalLinkOpenOption] {
        let options: [ExternalLinkOpenOption] = [.inApp, .safari, .chrome]
        return options.filter({ (option) -> Bool in
            return option.isAvailableForExternalLinks
        })
    }
    
    /// Returns an array (in order) of available options for opening youtube links
    ///
    /// - Returns: All options that are available for opening youtube links
    static func availableOptionsForYouTubeLinks() -> [ExternalLinkOpenOption] {
        let options: [ExternalLinkOpenOption] = [.inApp, .youTube, .proTube]
        return options.filter({ (option) -> Bool in
            return option.isAvailableForYouTubeLinks
        })
    }

    /// The display name for the option. Meant for display in the UI
    public var displayName: String {
        switch self {
        case .inApp:
            return "Beam"
        case .safari:
            return "Safari"
        case .chrome:
            return "Google Chrome"
        case .youTube:
            return "YouTube"
        case .proTube:
            return "Protube"
        default:
            return self.rawValue
        }
    }
    
    /// Returns a custom URL if available for the service
    ///
    /// - Parameter url: The original URL that can be used to form the custom URL with
    /// - Returns: The custom URL
    private func customUrl(for url: URL) -> URL? {
        switch self {
        case .proTube:
            guard let videoID = url.youTubeVideoID else {
                return nil
            }
            return URL(string: "protube://video/\(videoID)")
        case .youTube:
            guard let videoID = url.youTubeVideoID else {
                return nil
            }
            return URL(string: "youtube://watch/\(videoID)")
        case .safari:
            if url.isYouTubeURL {
                return url.mobileURL
            }
            return url
        case .chrome:
            guard var components = URLComponents(url: url.mobileURL, resolvingAgainstBaseURL: false) else {
                return nil
            }
            if components.scheme == "https" {
                components.scheme = "googlechromes"
            } else {
                components.scheme = "googlechrome"
            }
            guard let openUrl = components.url else {
                return nil
            }
            return openUrl
        case .onePassword:
            guard var components = URLComponents(url: url.mobileURL, resolvingAgainstBaseURL: false) else {
                return nil
            }
            if components.scheme == "https" {
                components.scheme = "ophttps"
            } else {
                components.scheme = "ophttp"
            }
            guard let openUrl = components.url else {
                return nil
            }
            return openUrl
        default:
            //If no URL is returned, the in-app option is used and a BeamSafariViewController will open
            return nil
        }
    }
    
    /// Handles the URL and translates it into opening another app or creating a UIViewController
    ///
    /// - Parameters:
    ///   - url: The original URL to open
    ///   - openImmediately: If the method should open an app/perform an action immediatly. If false the function will return nil if it is about to take an action that doesn't present a UIViewController (like opening another app)
    /// - Returns: A view controller to display, if available
    /// Discusstion: When the method returns a SFSafariViewController or UINavigationController it should be presented modally. Otherwise it can be used modally or pushed
    @discardableResult public func handleURL(_ url: URL, openImmediately: Bool = true) -> UIViewController? {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            //If we can't get any URL components from it, it's not a URL we can handle. Open another app instead
            if openImmediately {
                self.openCustomUrl(url, originalURL: url)
            }
            return nil
        }
        
        //Bugfix for NSDataDetector links, they might detect just host links because they were parsed incorrectly
        if urlComponents.scheme == nil && urlComponents.host == nil && urlComponents.path.substring(to: urlComponents.path.characters.index(urlComponents.path.startIndex, offsetBy: 1)) != "/" {
            urlComponents.host = urlComponents.path
            urlComponents.path = ""
            urlComponents.scheme = "http"
        }
        
        //If the scheme and host are both empty, we assume it's a relative reddit link
        if urlComponents.scheme == nil && urlComponents.host == nil {
            urlComponents.host = "reddit.com"
            urlComponents.scheme = "https"
        }
        
        //If the link is not a http(s) link, we can't handle it
        guard urlComponents.scheme == "http" || urlComponents.scheme == "https" else {
            if openImmediately {
                self.openCustomUrl(urlComponents.url ?? url, originalURL: url)
            }
            return nil
        }
        
        //If the link is a relative to a reddit comments thread (/comments/) or multireddit (/m/) we send it to the internal link routing for handling
        if urlComponents.host?.contains("reddit.com") == true && (urlComponents.path.contains("/comments/") || urlComponents.path.contains("/m/")) {
            urlComponents.scheme = "beam"
            if let beamUrl = urlComponents.url, InternalLinkRoutingController.shared.canRouteURL(beamUrl) {
                if openImmediately {
                    _ = InternalLinkRoutingController.shared.routeURL(beamUrl)
                }
                return nil
            }
        }
        
        //We seem to have a normal HTTP url to handle. Check if there is a custom URL for the current browser. If not, just open it using the in-app browser
        guard let componentsUrl = urlComponents.url, let customUrl = self.customUrl(for: componentsUrl) else {
            var inAppUrl = url
            if let componentsUrl = urlComponents.url {
                inAppUrl = componentsUrl
            }
            
            //If the URL is a YouTube URL we prefer to view the mobile URL in the in-app browser
            if inAppUrl.isYouTubeURL {
                inAppUrl = inAppUrl.mobileURL
            }
            
            let safariViewController = BeamSafariViewController(url: inAppUrl)
            //Bugfix: Not resetting the transitiondelegate causes the SafariViewController to disallow landscape
            safariViewController.transitioningDelegate = nil
            return safariViewController
        }
        
        //We have a valid custom URL for the service, if we are allowed to immediatly open it, we open it!
        if openImmediately {
            self.openCustomUrl(customUrl, originalURL: url)
        }
        return nil
    }
    
    /// Opens the actual custom URL, also creates a fallback if the custom URL fails
    ///
    /// - Parameters:
    ///   - url: The custom URL to open, this URL might have a custom URL scheme
    ///   - originalURL: The original URL, this url should have an HTTP or HTTPS url scheme
    private func openCustomUrl(_ url: URL, originalURL: URL) {
        if #available(iOS 10, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                if !success {
                    //If we can't open the custom URL, we fall back to the original URL.
                    UIApplication.shared.open(originalURL, options: [:], completionHandler: nil)
                }
            })
        } else {
            if !UIApplication.shared.canOpenURL(url) {
                //If opening the custom URL fails, fallback to the original URL
                UIApplication.shared.open(originalURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    /// Returns if the private browsing warning should be shown
    ///
    /// - Returns: If the private browsing warning should be shown
    static func shouldShowPrivateBrowsingWarning() -> Bool {
        return UserSettings[.privacyModeEnabled] && !UserSettings[.privateBrowserWarningShown]
    }
    
    /// Displays a warning that beam can't control the privacy status of a browser. This should be shown when the privacy mode is enabled in beam
    ///
    /// - Parameters:
    ///   - url: The url that is about to be showm
    ///   - viewController: The view controller to display the warning on
    static func showPrivateBrowsingWarning(_ url: URL, on viewController: UIViewController) {
        UserSettings[.privateBrowserWarningShown] = true
        var service = UserSettings[.browser].displayName
        if UserSettings[.browser] == .inApp {
            service = "Safari"
        }
        if url.isYouTubeURL {
            service = "YouTube"
        }
        let message = AWKLocalizedString("privacy-mode-warning-message").replacingOccurrences(of: "[SERVICE]", with: service)
        let alertController = BeamAlertController(title: AWKLocalizedString("privacy-mode-warning"), message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("continue-button"), style: UIAlertActionStyle.default, handler: { (_) in
            if let webViewController = UserSettings[.browser].handleURL(url) {
                viewController.present(webViewController, animated: true, completion: nil)
            }
        }))
        alertController.addCancelAction()
        viewController.present(alertController, animated: true, completion: nil)
    }
}
