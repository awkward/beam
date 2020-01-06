//
//  PostRedditMediaParser.swift
//  Snoo
//
//  Created by Rens Verhoeven on 10/08/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//

import UIKit
import CoreData

final class PostRedditMediaParser: PostMediaParser {

    class func isRedditHosted(json: NSDictionary) -> Bool {
        let redditHostedHosts = ["i.reddituploads.com", "i.reddit.com", "g.redditmedia.com", "i.redditmedia.com", "i.redd.it", "v.redd.it"]
        guard let urlString = (json["url"] as? String)?.stringByUnescapeHTMLEntities(),
            let url = URL(string: urlString),
            let host = url.host,
            redditHostedHosts.contains(host) else {
                return false
        }
        return true
    }
    
    func parseMedia(for post: Post, json: NSDictionary) -> [MediaObject] {
        if let crosspostList = json["crosspost_parent_list"] as? [NSDictionary], let crossPost = crosspostList.first {
            return self.parseMedia(for: post, json: crossPost)
        }
        guard PostRedditMediaParser.isRedditHosted(json: json), let objectContext = post.managedObjectContext else {
            print("Skipping URL because not reddit hosted \(String(describing: json["url"] as? String))")
            return []
        }
        
        if let isVideo = json.value(forKeyPath: "is_video") as? Bool, isVideo {
            if let mediaObject = self.parseRedditVideo(in: json, context: objectContext) {
                return [mediaObject]
            }
        } else if let images = json.value(forKeyPath: "preview.images") as? [[String: Any]], !images.isEmpty {
            guard images.count != post.mediaObjects?.count else {
                return []
            }
            if let mediaObjects = self.parseRedditImages(images, json: json, context: objectContext) {
                return mediaObjects
            }
        }
        return []
    }
    
    internal func parseRedditImages(_ images: [[String: Any]], json: NSDictionary, context: NSManagedObjectContext) -> [MediaObject]? {
        return images.compactMap { (image) -> MediaObject? in
            if let animatedGif = MediaAnimatedGIF(redditGIF: image, json: json, context: context) {
                return animatedGif
            } else {
                return MediaImage(redditImage: image, json: json, context: context)
            }
        }
    }
    
    internal func parseRedditVideo(in json: NSDictionary, context: NSManagedObjectContext) -> MediaObject? {
        if let animatedGif = MediaAnimatedGIF(redditGIF: nil, json: json, context: context) {
            return animatedGif
        } else {
            return MediaDirectVideo(redditVideoIn: json, context: context)
        }
    }
    
}

// MARK: - MediaImage Extension

extension MediaImage {
    
    convenience init?(redditImage image: [String: Any], json: NSDictionary, context: NSManagedObjectContext) {
        guard PostRedditMediaParser.isRedditHosted(json: json) else {
            return nil
        }
        self.init(context: context)
        self.parseRedditImage(image, in: json)
        self.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
    }
    
    private func parseRedditImage(_ image: [String: Any], in json: NSDictionary) {
        guard let source = image["source"] as? [String: Any] else {
            return
        }
        
        if let urlString = (source["url"] as? String)?.stringByUnescapeHTMLEntities(), let url = URL(string: urlString) {
            self.contentURL = url
        }
        self.pixelWidth = source["width"] as? NSNumber
        self.pixelHeight = source["height"] as? NSNumber
        
        self.parseRedditResolutionThumbnails(forImage: image, json: json)
    }
    
}

// MARK: - MediaDirectVideo Extension

extension MediaDirectVideo {
    
    convenience init?(redditVideoIn json: NSDictionary, context: NSManagedObjectContext) {
        guard PostRedditMediaParser.isRedditHosted(json: json), let isVideo = json["is_video"] as? Bool, isVideo else {
            return nil
        }
        guard let isGIF = json.value(forKeyPath: "secure_media.reddit_video.is_gif") as? Bool,
            json.value(forKeyPath: "secure_media.reddit_video") is [String: Any] && !isGIF else {
                return nil
        }
        self.init(context: context)
        self.parseRedditVideo(in: json)
        self.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
    }
    
    private func parseRedditVideo(in json: NSDictionary) {
        guard let redditVideo = json.value(forKeyPath: "secure_media.reddit_video") as? [String: Any] else {
            return
        }
        self.pixelHeight = redditVideo["height"] as? NSNumber
        self.pixelWidth = redditVideo["width"] as? NSNumber
        if let fallbackURLString = (redditVideo["fallback_url"] as? String)?.stringByUnescapeHTMLEntities(), let url = URL(string: fallbackURLString) {
            self.contentURL = url
        }
        if let hlsURLString = (redditVideo["hls_url"] as? String)?.stringByUnescapeHTMLEntities(), let url = URL(string: hlsURLString) {
            self.videoURL = url
        }
        
        guard let image = (json.value(forKeyPath: "preview.images") as? [[String: Any]])?.first else {
            return
        }
        
        self.parseRedditResolutionThumbnails(forImage: image, json: json)
    }
    
}

// MARK: - MediaAnimatedGIF Extension

extension MediaAnimatedGIF {
    
    convenience init?(redditGIF image: [String: Any]?, json: NSDictionary, context: NSManagedObjectContext) {
        guard PostRedditMediaParser.isRedditHosted(json: json) else {
            return nil
        }
        let isVideo = json["is_video"] as? Bool ?? false
        let isGIF = json.value(forKeyPath: "secure_media.reddit_video.is_gif") as? Bool ?? false
        
        if isVideo && isGIF {
            // This is a new type of reddit GIF uploaded as video only!
            self.init(context: context)
            self.parseRedditVideo(in: json)
            self.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
        } else if let image = image, let variants = image["variants"] as? [String: Any], variants["mp4"] is [String: Any] {
            // This is the old type of gif to video conversion gif on reddit
            self.init(context: context)
            self.parseRedditImage(image, in: json)
            self.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
        } else {
            return nil
        }
    }
    
    private func parseRedditVideo(in json: NSDictionary) {
        guard let redditVideo = json.value(forKeyPath: "secure_media.reddit_video") as? [String: Any] else {
            return
        }
        self.pixelHeight = redditVideo["height"] as? NSNumber
        self.pixelWidth = redditVideo["width"] as? NSNumber
        if let fallbackURLString = (redditVideo["fallback_url"] as? String)?.stringByUnescapeHTMLEntities(), let url = URL(string: fallbackURLString) {
            self.contentURL = url
        }
        if let hlsURLString = (redditVideo["hls_url"] as? String)?.stringByUnescapeHTMLEntities(), let url = URL(string: hlsURLString) {
            self.videoURL = url
        }
        
        guard let image = (json.value(forKeyPath: "preview.images") as? [[String: Any]])?.first else {
            return
        }
        
        self.parseRedditResolutionThumbnails(forImage: image, json: json)
    }
    
    private func parseRedditImage(_ image: [String: Any], in json: NSDictionary) {
        guard let variants = image["variants"] as? [String: Any],
            let mp4Variant = variants["mp4"] as? [String: Any] else {
                return
        }
        
        if let resolutions = mp4Variant["resolutions"] as? [[String: Any]], let bestResolution = resolutions.last {
            if let urlString = (bestResolution["url"] as? String)?.stringByUnescapeHTMLEntities(), let url = URL(string: urlString) {
                self.videoURL = url
                self.contentURL = url
            }
            self.pixelWidth = bestResolution["width"] as? NSNumber
            self.pixelHeight = bestResolution["height"] as? NSNumber
        } else if let source = mp4Variant["source"] as? [String: Any] {
            if let urlString = (source["url"] as? String)?.stringByUnescapeHTMLEntities(), let url = URL(string: urlString) {
                self.videoURL = url
                self.contentURL = url
            }
            self.pixelWidth = source["width"] as? NSNumber
            self.pixelHeight = source["height"] as? NSNumber
        }
        
        self.parseRedditResolutionThumbnails(forImage: image, json: json)
    }
    
}
