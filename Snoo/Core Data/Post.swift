//
//  Post.swift
//  Snoo
//
//  Created by Robin Speijer on 10-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

extension Notification.Name {
    
    public static let PostDidChangeVisitedState = Notification.Name(rawValue: "PostDidChangeVisitedStateNotification")
    
}

@objc(Post)
public final class Post: Content {

    @NSManaged open var commentCount: NSNumber?

    @NSManaged open var thumbnailUrlString: String?
    @NSManaged open var title: String?
    @NSManaged open var type: NSNumber?
    @NSManaged open var urlString: String?
    @NSManaged open var collection: PostCollection?
    @NSManaged open var comments: NSSet?
    @NSManaged open var flairText: String?
    @NSManaged open var subreddit: Subreddit?
    @NSManaged open var postMetadata: PostMetadata?
    
    //Required properties with default value
    @NSManaged open var isContentNSFW: NSNumber //Default: No
    @NSManaged open var isContentSpoiler: NSNumber //Default: No
    @NSManaged open var isSelfText: NSNumber //Default: No
    @NSManaged open var isHidden: NSNumber //Default: No
    
    open class override func entityName() -> String {
        return "Post"
    }
    
    override class func insertObject(_ context: NSManagedObjectContext) -> SyncObject {
        let entityDescription = NSEntityDescription.entity(forEntityName: entityName(), in: context)!
        return Post(entity: entityDescription, insertInto: context)
    }
    
    override func parseObject(_ json: NSDictionary, cache: NSCache<NSString, NSManagedObjectID>?) throws {
        try super.parseObject(json, cache: cache)
        
        if self.subreddit == nil {
            //Only set the subreddit if it's missing, the subreddit won't be updated later. This method takes a lot of time
            if let
                name = json["subreddit_id"] as? String,
                let context = self.managedObjectContext,
                let identifier = SyncObject.identifierWithObjectName(name),
                let subreddit = try Subreddit.objectWithIdentifier(identifier, cache: cache, context: context) as? Subreddit {
                    self.subreddit = subreddit
                    
                    // If the linked subreddit is just new in this context
                    if self.managedObjectContext?.insertedObjects.contains(subreddit) == true {
                        if let displayName = json["subreddit"] as? String, self.subreddit?.displayName == nil {
                            self.subreddit?.displayName = displayName
                            self.subreddit?.sectionName = displayName.substring(to: displayName.index(after: displayName.startIndex))
                        }
                    }
                    
            }
        }
        
        if let URLString = json["url"] as? String {
            self.urlString = URLString.stringByUnescapeHTMLEntities()
        }
        
        self.title = (json["title"] as? String)?.stringByUnescapeHTMLEntities() ?? self.title
        self.isHidden = json["hidden"] as? NSNumber ?? self.isHidden
        self.isSelfText = json["is_self"] as? NSNumber ?? self.isSelfText
        self.content = (json["selftext"] as? String)?.stringByUnescapeHTMLEntities() ?? self.content
        self.commentCount = json["num_comments"] as? NSNumber ?? self.commentCount
        self.isContentNSFW = json["over_18"] as? NSNumber ?? self.isContentNSFW
        self.isContentSpoiler = json["spoiler"] as? NSNumber ?? self.isContentSpoiler
        self.flairText = json["link_flair_text"] as? String ?? self.flairText
        
        //Mark the post visited if the API knows this post has been visited
        if let visited = json["visited"] as? NSNumber, visited.boolValue == true {
            //Mark the post, but don't save the context, this will already be done after parsing
            self.markVisited(save: false)
        }
        
        //Thumbnail can contain reddit icon strings, we should ignore those
        if let thumbnail = json["thumbnail"] as? String, thumbnail.contains("http") {
              self.thumbnailUrlString = thumbnail.stringByUnescapeHTMLEntities()
        }
        if let previewJSON = json["preview"] as? NSDictionary, let images = previewJSON["images"] as? NSArray, let firstImage = images.firstObject as? NSDictionary, let resolutions = firstImage["resolutions"] as? NSArray {
            var resolution: NSDictionary?
            if resolutions.count >= 2 {
                resolution = resolutions[1] as? NSDictionary
            } else {
                resolution = resolutions.lastObject as? NSDictionary
            }
            if let resolution = resolution {
                self.thumbnailUrlString = (resolution["url"] as? String)?.stringByUnescapeHTMLEntities() ?? self.thumbnailUrlString
            }
        }
        
        //Parse media info
        self.parseMediaInformation(json)
        
        //Mark the post as spoiler if the title contains a spoiler tag.
        //This is legacy for some old posts that have not been marked spoiler yet
        //Reddit change: https://www.reddit.com/r/announcements/comments/5or86n/spoilers_tags_for_posts/
        if let title = self.title?.lowercased() {
            let nonSpoilerWords = ["no spoiler", "not spoiler", "non spoiler", "no-spoiler", "not-spoiler", "non-spoiler"]
            let spoilerWords = ["spoiler"]
            if self.isContentSpoiler == false {
                for word in spoilerWords {
                    if title.contains(word) {
                        self.isContentSpoiler = true
                    }
                }
            }
            for word in nonSpoilerWords {
                if title.contains(word) {
                    self.isContentSpoiler = false
                }
            }
        }
    }
    
    /// Returns if a post has been visited or not.
    /// See `markVisited(save:)` on marking a post as visited
    open var isVisited: Bool {
        guard let metadata = self.postMetadata else {
            return false
        }
        return metadata.visited?.boolValue ?? false
    }
    
    /// Marks the post as visited and sends this to the reddit API if needed.
    /// This can not be undone
    ///
    /// - Parameter save: If the object context should be saved and the state change should be sent to the reddit server. Defaults to true
    open func markVisited(save: Bool = true) {
        var postMetadata: PostMetadata?
        if let existingMetadata = self.postMetadata {
            postMetadata = existingMetadata
        } else {
            if let managedObjectContext = self.managedObjectContext {
                postMetadata = PostMetadata.insertObject(managedObjectContext)
                self.postMetadata = postMetadata
            }
            
        }
        guard let metadata = postMetadata else {
            return
        }
        let visitedChanged = self.isVisited == false
        metadata.visited = NSNumber(value: true)
        
        if visitedChanged && save {
            //We don't care if there was an error, since isVisited is just an extra feature and not important
            try? self.managedObjectContext?.save()
            
            NotificationCenter.default.post(name: .PostDidChangeVisitedState, object: self)
            //Send the visit of to the server queue for goldmembers
            UserActivityController.shared.addVisit(self)
        }
    }
    
    fileprivate func parseMediaInformation(_ dictionary: NSDictionary) {
        guard let URLString: String = self.urlString, let url = URL(string: URLString), let urlHost = url.host else {
            return
        }
        
        guard let preview: NSDictionary = dictionary["preview"] as? NSDictionary else {
            return
        }
        guard let images: NSArray = preview["images"] as? NSArray else {
            return
        }
        guard images.count != self.mediaObjects?.count else {
            return
        }
        
        let redditUploadURLHosts: [String] = ["i.reddituploads.com", "i.reddit.com", "g.redditmedia.com", "i.redditmedia.com", "i.redd.it"]
        if redditUploadURLHosts.contains(urlHost) {
            guard let objectContext: NSManagedObjectContext = self.managedObjectContext else {
                return
            }
            if let mediaObjects: [MediaObject] = MediaObject.parseMediaPreview(preview, context: objectContext) {
                self.mediaObjects = NSOrderedSet(array: mediaObjects)
            }
        }
     }
    
    open override func redditDictionaryRepresentation() -> [String: Any] {
        var dictionary = super.redditDictionaryRepresentation()
        
        dictionary["subreddit_id"] = self.subreddit?.objectName as AnyObject?
        dictionary["subreddit"] = self.subreddit?.displayName as AnyObject?
        dictionary["url"] = self.urlString as AnyObject?
        dictionary["title"] = self.title as AnyObject?
        dictionary["hidden"] = self.isHidden
        dictionary["is_self"] = self.isSelfText
        dictionary["selftext"] = self.content as AnyObject?
        dictionary["num_comments"] = self.commentCount
        dictionary["over_18"] = self.isContentNSFW
        dictionary["visited"] = NSNumber(value: self.isVisited)

        return dictionary
    }

}
