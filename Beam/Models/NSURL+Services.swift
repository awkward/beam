//
//  URLMetadata+Video.swift
//  beam
//
//  Created by Robin Speijer on 19-11-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import Foundation

public enum URLType: String {
    case article = "article"
    case website = "website"
    case twitter = "twitter"
    case video = "video"
    case other = ""
}

extension URL {
    
    var estimatedURLType: URLType {
        if self.isYouTubeURL {
            return URLType.video
        } else {
            return URLType.other
        }
    }
    
    var isYouTubeURL: Bool {
        //Unwrapping two times creates some extra CPU time
        if let host = self.host?.lowercased(), host.contains("youtu.be") || host.contains("youtube.com") || host.contains("youtube.co.uk") {
            return true
        }
        return false
    }
    
    var mobileURL: URL {
        if self.isYouTubeURL {
            return self.mobileYouTubeURL ?? self
        }
        return self
    }
    
    fileprivate var mobileYouTubeURL: URL? {
        guard let youTubeID = self.youTubeVideoID else {
            return nil
        }
        return  URL(string: "https://m.youtube.com/watch?v=\(youTubeID)")
        
    }
    
    var youTubeVideoID: String? {
        guard self.isYouTubeURL else {
            return nil
        }
        
        guard let components: URLComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        let path: String = components.path
        if let host: String = components.host, host.contains("youtu.be") == true {
            let videoIdentifier: String = path.replacingOccurrences(of: "/", with: "")
            return videoIdentifier
        } else {
            guard let queryItems: [URLQueryItem] = components.queryItems else {
                return nil
            }
            //Check if we have an attribution link
            let filtered: [URLQueryItem] = queryItems.filter({ (item) -> Bool in
                return  item.name == "u" || item.name == "amp;u"
            })
            guard let item: URLQueryItem = filtered.first, let attributionLinkPath: String = item.value else {
                //We do not have attribution link quert items. So just continue getting the "v" query item
                let filteredQueryItems: [URLQueryItem] = queryItems.filter({ (item) -> Bool in
                    return  item.name == "v" || item.name == "amp;v"
                })
                guard let queryItem: URLQueryItem = filteredQueryItems.first, let videoID: String = queryItem.value else {
                    return nil
                }
                return videoID
            }
            //We have an attribution link, so parse it
            guard let attributionLinkComponents: URLComponents = URLComponents(string: attributionLinkPath),
                let attributionLinkQueryItems: [URLQueryItem] = attributionLinkComponents.queryItems else {
                return nil
            }
            let filteredQueryItems: [URLQueryItem] = attributionLinkQueryItems.filter({ (item) -> Bool in
                return  item.name == "v" || item.name == "amp;v"
            })
            guard let queryItem: URLQueryItem = filteredQueryItems.first, let videoID: String = queryItem.value else {
                return nil
            }
            return videoID
            
        }
    }
    
}
