//
//  MediaObject+CoreDataClass.swift
//  beam
//
//  Created by Rens Verhoeven on 05/07/2018.
//  Copyright © 2018 Awkward. All rights reserved.
//
//

import Foundation
import CoreData

public class MediaObject: NSManagedObject, SyncableObject {
    
    public typealias SyncableRoot = MediaObject
    
    public var isNSFW: Bool {
        set {
            self.isNSFWNumber = NSNumber(value: newValue)
        }
        get {
            return self.isNSFWNumber?.boolValue ?? false
        }
    }
    
    public var pixelSize: CGSize {
        set {
            self.pixelHeight = NSNumber(value: Int(newValue.height))
            self.pixelWidth = NSNumber(value: Int(newValue.width))
        }
        get {
            return CGSize(width: self.pixelWidth?.intValue ?? 0, height: self.pixelHeight?.intValue ?? 0)
        }
    }
    
    public required override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    public class func entityName() -> String {
        return "MediaObject"
    }
    
    open func thumbnailWithSize(_ size: CGSize) -> Thumbnail? {
        let widerImageFetchRequest = NSFetchRequest<Thumbnail>(entityName: Thumbnail.entityName())
        let scale: CGFloat = min(2.0, UIScreen.main.scale)
        widerImageFetchRequest.predicate = NSPredicate(format: "mediaObject == %@ && pixelWidth >= %f", self, size.width * scale)
        widerImageFetchRequest.sortDescriptors = [NSSortDescriptor(key: "pixelWidth", ascending: true)]
        
        do {
            if let biggerThumb = (try self.managedObjectContext?.fetch(widerImageFetchRequest))?.first {
                return biggerThumb
            } else {
                let smallerImageFetchRequest = NSFetchRequest<Thumbnail>(entityName: Thumbnail.entityName())
                smallerImageFetchRequest.predicate = NSPredicate(format: "mediaObject == %@ && pixelWidth <= %f", self, size.width * scale)
                smallerImageFetchRequest.sortDescriptors = [NSSortDescriptor(key: "pixelWidth", ascending: false)]
                if let biggerThumb = (try self.managedObjectContext?.fetch(smallerImageFetchRequest))?.first {
                    return biggerThumb
                } else {
                    let anyImageFetchRequest = NSFetchRequest<Thumbnail>(entityName: Thumbnail.entityName())
                    anyImageFetchRequest.predicate = NSPredicate(format: "mediaObject == %@", self)
                    anyImageFetchRequest.sortDescriptors = [NSSortDescriptor(key: "pixelWidth", ascending: false)]
                    if let thumbnail = (try self.managedObjectContext?.fetch(anyImageFetchRequest))?.first {
                        return thumbnail
                    }
                    return nil
                }
            }
        } catch {
            NSLog("Could not fetch thumbnails for media object %@: \(error)", self)
            return nil
        }
    }
    
    internal func parseRedditResolutionThumbnails(forImage image: [String: Any], json: NSDictionary) {
        guard let resolutions = image["resolutions"] as? [[String: Any]],
            let managedObjectContext = self.managedObjectContext else {
                return
        }
        let thumbnails = resolutions.map({ (resolutionInfo) -> Thumbnail in
            let thumbnail = Thumbnail(context: managedObjectContext)
            if let urlString = (resolutionInfo["url"] as? String)?.stringByUnescapeHTMLEntities(), let url = URL(string: urlString) {
                thumbnail.url = url
            }
            thumbnail.pixelWidth = resolutionInfo["width"] as? NSNumber
            thumbnail.pixelHeight = resolutionInfo["height"] as? NSNumber
            thumbnail.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
            return thumbnail
        })
        self.thumbnails = Set(thumbnails)
    }
    
}
