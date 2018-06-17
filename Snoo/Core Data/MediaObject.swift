//
//  MediaObject.swift
//  Snoo
//
//  Created by Robin Speijer on 16-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public final class MediaObject: NSManagedObject, MetadataHandling {

    @NSManaged open var identifier: String?
    @NSManaged open var width: NSNumber?
    @NSManaged open var height: NSNumber?
    @NSManaged open var captionTitle: String?
    @NSManaged open var captionDescription: String?
    @NSManaged open var contentURLString: String?
    @NSManaged open var thumbnails: NSSet?
    @NSManaged open var metadata: NSDictionary?
    @NSManaged open var content: Content?
    @NSManaged open var expirationDate: Date?
    
    public required override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    open class func entityName() -> String {
        return "MediaObject"
    }
    
    class func parseMediaPreview(_ json: NSDictionary, context: NSManagedObjectContext) -> [MediaObject]? {
        guard let images: NSArray = json["images"] as? NSArray else {
            return nil
        }
        
        var imageObjects = [MediaObject]()
        
        for image in images {
            if let imageDictionary: NSDictionary = image as? NSDictionary {
                let newMediaObject = NSEntityDescription.insertNewObject(forEntityName: self.entityName(), into: context) as! MediaObject
                newMediaObject.parseImagePreview(imageDictionary)
                imageObjects.append(newMediaObject)
            }
        }
        
        return imageObjects
    }
    
    fileprivate func parseImagePreview(_ json: NSDictionary) {
        if let source = json["source"] as? NSDictionary {
            if let variants: NSDictionary = json["variants"] as? NSDictionary, let mp4Variant: NSDictionary = variants["mp4"] as? NSDictionary, let mp4Resolutions: NSArray = mp4Variant["resolutions"] as? NSArray {
                let resolutionsSorted: NSArray = self.resolutionsSortedBySize(mp4Resolutions)
                if let bestMP4Source: NSDictionary = resolutionsSorted.firstObject as? NSDictionary {
                    //Note: The URL in the source of the MP4 variant is almost always a corrupt file. Use the highest size instead
                    self.contentURLString = (bestMP4Source["url"] as? String)?.stringByUnescapeHTMLEntities()
                    self.metadata = NSDictionary(object: NSNumber(value: true as Bool), forKey: "animated" as NSCopying)
                    self.width = bestMP4Source["width"] as? NSNumber
                    self.height = bestMP4Source["height"] as? NSNumber
                } else {
                    self.contentURLString = (source["url"] as? String)?.stringByUnescapeHTMLEntities()
                    self.width = source["width"] as? NSNumber
                    self.height = source["height"] as? NSNumber
                }
            } else {
                self.contentURLString = (source["url"] as? String)?.stringByUnescapeHTMLEntities()
                self.width = source["width"] as? NSNumber
                self.height = source["height"] as? NSNumber
            }
            
            if let thumbnails: NSArray = json["resolutions"] as? NSArray {
                var thumbnailObjects = [Thumbnail]()
                for thumbnail in thumbnails {
                    guard let thumbnailDict: NSDictionary = thumbnail as? NSDictionary else {
                        return
                    }
                    let newThumbnail = NSEntityDescription.insertNewObject(forEntityName: Thumbnail.entityName(), into: self.managedObjectContext!) as! Thumbnail
                    newThumbnail.urlString = (thumbnailDict["url"] as? String)?.stringByUnescapeHTMLEntities()
                    newThumbnail.width = thumbnailDict["width"] as? NSNumber
                    newThumbnail.height = thumbnailDict["height"] as? NSNumber
                    newThumbnail.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
                    thumbnailObjects.append(newThumbnail)
                }
                self.thumbnails = NSSet(array: thumbnailObjects)
            } else {
                self.thumbnails = nil
            }
            self.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
        }
    }
    
    fileprivate func resolutionsSortedBySize(_ resolutions: NSArray) -> NSArray {
        
        let array: NSArray = resolutions.sorted { (object1, object2) -> Bool in
            guard let resolution1: NSDictionary = object1 as? NSDictionary, let resolution2: NSDictionary = object2 as? NSDictionary else {
                return false
            }
            guard let width1: NSNumber = resolution1["width"] as? NSNumber, let width2: NSNumber = resolution2["width"] as? NSNumber else {
                return false
            }
            guard let height1: NSNumber = resolution1["height"] as? NSNumber, let height2: NSNumber = resolution2["height"] as? NSNumber else {
                return false
            }
            let size1: Float = width1.floatValue * height1.floatValue
            let size2: Float = width2.floatValue * height2.floatValue
            return size1 > size2
        } as NSArray
        return array
    }
    
    open func thumbnailWithSize(_ size: CGSize) -> Thumbnail? {
        let widerImageFetchRequest = NSFetchRequest<Thumbnail>(entityName: Thumbnail.entityName())
        let scale: CGFloat = min(2.0, UIScreen.main.scale)
        widerImageFetchRequest.predicate = NSPredicate(format: "mediaObject == %@ && width >= %f", self, size.width * scale)
        widerImageFetchRequest.sortDescriptors = [NSSortDescriptor(key: "width", ascending: true)]
        
        do {
            if let biggerThumb = (try self.managedObjectContext?.fetch(widerImageFetchRequest))?.first {
                return biggerThumb
            } else {
                let smallerImageFetchRequest = NSFetchRequest<Thumbnail>(entityName: Thumbnail.entityName())
                smallerImageFetchRequest.predicate = NSPredicate(format: "mediaObject == %@ && width <= %f", self, size.width * scale)
                smallerImageFetchRequest.sortDescriptors = [NSSortDescriptor(key: "width", ascending: false)]
                if let biggerThumb = (try self.managedObjectContext?.fetch(smallerImageFetchRequest))?.first {
                    return biggerThumb
                } else {
                    let anyImageFetchRequest = NSFetchRequest<Thumbnail>(entityName: Thumbnail.entityName())
                    anyImageFetchRequest.predicate = NSPredicate(format: "mediaObject == %@", self)
                    anyImageFetchRequest.sortDescriptors = [NSSortDescriptor(key: "width", ascending: false)]
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
}
