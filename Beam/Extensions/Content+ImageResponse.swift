//
//  Content+ImageResponse.swift
//  Beam
//
//  Created by Rens Verhoeven on 30/01/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CherryKit
import CoreData

extension Content {

    @discardableResult
    func insertMediaObjects(with response: ImageResponse) -> [MediaObject] {
        var mediaObjects = [MediaObject]()
        
        //Images with a smaller aspect ratio are not allowed
        guard response.imageSpecs.filter({ (spec) -> Bool in
            guard spec.size.width > 0 && spec.size.height > 0 else {
                return false
            }
            return spec.size.aspectRatio < StreamImagesOperation.minimumAspectRatio
        }).count <= 0 else {
            return mediaObjects
        }
        
        // Old mediaobject content strings
        let urlStrings = self.mediaObjects?.array.map({ (obj) -> String in
            return (obj as? MediaObject)?.contentURL?.absoluteString ?? ""
        })
        let oldUrlStrings = Set<String>(urlStrings ?? [String]())
        
        for spec in response.imageSpecs {
            if Content.isGiphyURL(spec: spec) {
                //A giphy URL needs special treatment to get a static image and the MP4. If not continue with the parsing
                if let mediaObject = Content.parseGiphyURL(spec: spec, content: self) {
                    mediaObjects.append(mediaObject)
                }
                //Go to the next round of the for loop
                continue
            }
            
            var contentURL = spec.URL
            if let MP4URL = spec.MP4URL {
                //If an MP4 URL is availble, use it instead!
                contentURL = MP4URL
            }
            
            if let host = contentURL.host, host.contains("imgur.com") == true, contentURL.pathExtension == "gifv" {
                //Change imgur .gifv urls to .mp4
                contentURL = contentURL.deletingPathExtension().appendingPathExtension("mp4")
            }
            
            // Don't add regular gifs, they are data hogs!
            if contentURL.pathExtension == "gif" {
                //Do add gifs from imgur, they can be easily translated to mp4
                guard let host = contentURL.host, host.contains("imgur.com") == true else {
                    continue
                }
                contentURL = contentURL.deletingPathExtension().appendingPathExtension("mp4")
            }
            
            // Don't re-add when already existing
            let contentURLString: String = contentURL.absoluteString
            if oldUrlStrings.contains(contentURLString) {
                continue
            }
            
            var type: MediaObject.Type = MediaImage.self
            if spec.animated == true {
                type = MediaAnimatedGIF.self
            }
            
            let mediaObject = self.insertNewMediaObject(of: type)
            mediaObject.pixelSize = spec.size
            mediaObject.galleryItem.size = spec.size
            mediaObject.isNSFW = spec.nsfw ?? false
            mediaObject.captionTitle = spec.title
            mediaObject.captionDescription = spec.imageDescription
            mediaObject.contentURL = contentURL
            if let animatedGIF = mediaObject as? MediaAnimatedGIF {
                animatedGIF.videoURL = contentURL
            }
            mediaObject.identifier = spec.identifier
            
            Content.insertImgurThumbnailsToMediaObject(mediaObject)
            Content.insertGfycatThumbnailsToMediaObject(mediaObject)
            
            mediaObjects.append(mediaObject)
        }
        return mediaObjects
    }
    
    fileprivate class func isGiphyURL(spec: ImageSpec) -> Bool {
        return spec.originalURL.host?.contains("giphy.com") == true
    }
    
    fileprivate class func parseGiphyURL(spec: ImageSpec, content: Content) -> MediaObject? {
        var urlString = spec.originalURL.absoluteString
        do {
            var giphyID: String?
            
            //Sanitize the URL first to make the regular expression easier
            urlString = urlString.replacingOccurrences(of: "giphy.gif", with: "")
            urlString = urlString.replacingOccurrences(of: "media", with: "")
            urlString = urlString.replacingOccurrences(of: "giphy.com", with: "")
            urlString = urlString.replacingOccurrences(of: "gifs", with: "")
            urlString = urlString.replacingOccurrences(of: ".gif", with: "")
            
            let regularExpression = try NSRegularExpression(pattern: "((-|/)([a-zA-Z0-9]+?)(?:/|$))", options: [])
            let matches = regularExpression.matches(in: urlString, options: [], range: NSRange(location: 0, length: (urlString as NSString).length))
            let nsString = urlString as NSString
            
            if let stringRange = matches.first(where: { (match) -> Bool in
                return match.numberOfRanges >= 4
            })?.range(at: 3) {
                giphyID = nsString.substring(with: stringRange)
            }
            
            if giphyID == nil {
                //Try the last part of the path
                let components = urlString.components(separatedBy: "/")
                if let possibleID = components.last, possibleID.contains("giphy") == false && possibleID.contains("media") == false && possibleID.contains("gif") == false {
                    giphyID = possibleID
                }
                
            }
            guard let identifier = giphyID else {
                return nil
            }
            
            guard let context = content.managedObjectContext else {
                return nil
            }
            
            let mediaObject = MediaAnimatedGIF(context: context)
            mediaObject.pixelSize = spec.size
            mediaObject.isNSFW = spec.nsfw ?? false
            mediaObject.contentURL = URL(string: "https://media.giphy.com/media/\(identifier)/giphy.mp4")
            mediaObject.videoURL = URL(string: "https://media.giphy.com/media/\(identifier)/giphy.mp4")
            mediaObject.identifier = spec.identifier
            
            let thumbnail = Thumbnail(context: context)
            thumbnail.url = URL(string: "https://media.giphy.com/media/\(identifier)/giphy_s.gif")
            thumbnail.pixelWidth = NSNumber(value: Float(spec.size.width))
            thumbnail.pixelHeight = NSNumber(value: Float(spec.size.height))
            
            mediaObject.thumbnails = Set([thumbnail])
            
            return mediaObject
            
        } catch {
            return nil
        }
        
    }
}

// MARK: - Thumbnails

extension Content {
    
    fileprivate class func insertImgurThumbnailsToMediaObject(_ object: MediaObject) {
        guard let context = object.managedObjectContext else {
            return
        }
        let pattern = "^https?://.*imgur.com/"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            if let url = object.contentURL, regex.firstMatch(in: url.absoluteString, options: [], range: NSRange(location: 0, length: (url.absoluteString as NSString).length)) != nil {
                var pathExtension = url.pathExtension
                
                let pathWithoutExtension = (pathExtension as NSString).length > 0 ? url.path.replacingOccurrences(of: ".\(pathExtension)", with: "") : url.path
                //Imgur will always respond with a valid image if the extension is PNG
                if pathExtension.count <= 0 {
                    pathExtension = "png"
                }
                if ["gif", "gifv", "mp4"].contains(pathExtension) {
                    pathExtension = "png"
                }
                
                let imgurProportions = ["t": 160, "m": 320, "l": 640, "h": 1024]
                let thumbnails = imgurProportions.map({ (key: String, side: Int) -> Thumbnail in
                    let thumbnailPath = "\(pathWithoutExtension)\(key).\(pathExtension)"
                    let thumbnail = Thumbnail(context: context)
                    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    urlComponents?.scheme = "https"
                    urlComponents?.path = thumbnailPath
                    
                    thumbnail.url = urlComponents?.url
                    thumbnail.pixelSize = CGSize(width: side, height: side)
                    
                    return thumbnail
                })
                object.thumbnails = Set(thumbnails)
                
            }
        } catch {
            
        }
    }
    
    fileprivate class func insertGfycatThumbnailsToMediaObject(_ object: MediaObject) {
        guard let context = object.managedObjectContext else {
            return
        }
        guard let url = object.contentURL, var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), url.absoluteString.contains("gfycat.com") else {
            return
        }
        urlComponents.host = "thumbs.gfycat.com"
        urlComponents.scheme = "https"
        
        let path = urlComponents.path
        let pathExtension = url.pathExtension
        var identifier = path
        let extensionRange = path.index(path.endIndex, offsetBy: -1 * pathExtension.count - 1)..<path.endIndex
        identifier.removeSubrange(extensionRange)
        
        urlComponents.path = "\(identifier)-poster.jpg"
        guard let thumbnailURL = urlComponents.url else {
            return
        }
        let thumbnail = Thumbnail(context: context)
        thumbnail.mediaObject = object
        thumbnail.url = thumbnailURL
        thumbnail.pixelSize = .zero
    }
    
}
