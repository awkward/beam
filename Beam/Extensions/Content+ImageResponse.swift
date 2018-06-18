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
            return (obj as? MediaObject)?.contentURLString ?? ""
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
            // Don't add regular gifs, they are data hogs!
            if contentURL.pathExtension == "gif" {
                //Do add gifs from imgur, they can be easily translated to mp4
                if let host = contentURL.host, host.contains("imgur.com") == true {
                    let newURL = contentURL.deletingPathExtension().appendingPathExtension("mp4")
                    contentURL = newURL
                } else {
                    continue
                }
            }
            
            // Don't readd when already existing
            let contentURLString: String = contentURL.absoluteString
            if oldUrlStrings.contains(contentURLString) {
                continue
            }
            
            let mediaObject = self.insertNewMediaObject()
            mediaObject.galleryItem.size = spec.size
            mediaObject.galleryItem.animated = spec.animated
            mediaObject.galleryItem.nsfw = spec.nsfw
            mediaObject.captionTitle = spec.title
            mediaObject.captionDescription = spec.imageDescription
            mediaObject.contentURLString = contentURL.absoluteString
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
            
            let mediaObject = content.insertNewMediaObject()
            mediaObject.galleryItem.size = spec.size
            mediaObject.galleryItem.animated = true
            mediaObject.galleryItem.nsfw = spec.nsfw
            mediaObject.contentURLString = "https://media.giphy.com/media/\(identifier)/giphy.mp4"
            mediaObject.identifier = spec.identifier
            
            let thumbnail = NSEntityDescription.insertNewObject(forEntityName: Thumbnail.entityName(), into: mediaObject.managedObjectContext!) as! Thumbnail
            thumbnail.mediaObject = mediaObject
            thumbnail.urlString = "https://media.giphy.com/media/\(identifier)/giphy_s.gif"
            thumbnail.width = NSNumber(value: Float(spec.size.width))
            thumbnail.height = NSNumber(value: Float(spec.size.height))
            
            return mediaObject
            
        } catch {
            return nil
        }
        
    }
    
    fileprivate class func insertImgurThumbnailsToMediaObject(_ object: MediaObject) {
        let pattern = "^https?://.*imgur.com/"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            if let string = object.contentURLString,
                let url = URL(string: string), regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: (string as NSString).length)) != nil {
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
                object.thumbnails = NSSet(array: imgurProportions.map({ (key: String, side: Int) -> Thumbnail in
                    let thumbnailPath = "\(pathWithoutExtension)\(key).\(pathExtension)"
                    let thumbnail = NSEntityDescription.insertNewObject(forEntityName: Thumbnail.entityName(), into: object.managedObjectContext!) as! Thumbnail
                    var urlComponents = URLComponents(string: string)
                    urlComponents?.scheme = "https"
                    urlComponents?.path = thumbnailPath
                    
                    thumbnail.urlString = urlComponents?.string
                    thumbnail.width = NSNumber(value: side)
                    thumbnail.height = NSNumber(value: side)
                    
                    return thumbnail
                }))
                
            }
        } catch {
            
        }
    }
    
    fileprivate class func insertGfycatThumbnailsToMediaObject(_ object: MediaObject) {
        if let urlString = object.contentURLString, let url = URL(string: urlString), var urlComponents = URLComponents(string: urlString), urlString.contains("gfycat.com") {
            urlComponents.host = "thumbs.gfycat.com"
            urlComponents.scheme = "https"
            
            let path = urlComponents.path
            let pathExtension = url.pathExtension
            var identifier = path
            let extensionRange = path.index(path.endIndex, offsetBy: -1 * pathExtension.count - 1)..<path.endIndex
            identifier.removeSubrange(extensionRange)
            
            urlComponents.path = "\(identifier)-poster.jpg"
            if let thumbnailURL = urlComponents.url {
                
                let thumbnail = NSEntityDescription.insertNewObject(forEntityName: Thumbnail.entityName(), into: object.managedObjectContext!) as! Thumbnail
                thumbnail.mediaObject = object
                thumbnail.urlString = thumbnailURL.absoluteString
                thumbnail.width = NSNumber(value: 0)
                thumbnail.height = NSNumber(value: 0)
                
            }
            
        }
    }
    
}
