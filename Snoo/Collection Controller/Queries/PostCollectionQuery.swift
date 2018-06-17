//
//  PostCollectionQuery.swift
//  Snoo
//
//  Created by Robin Speijer on 26-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

public final class PostCollectionQuery: ContentCollectionQuery {

    open var subreddit: Subreddit? // Subreddit permalink to get posts or comments from that subreddit
    
    override var apiPath: String {
        assert(!Thread.isMainThread)
        
        let context = DataController.shared.privateContext
        
        var permalink: String?
        var displayName: String?
        context?.performAndWait({ () -> Void in
            if let subredditID = self.subreddit?.objectID {
                do {
                    let subreddit = try context?.existingObject(with: subredditID) as? Subreddit
                    permalink = subreddit?.permalink
                    displayName = subreddit?.displayName
                } catch {
                    permalink = nil
                    displayName = nil
                }
            }
        })
        
        if let subredditPermalink = permalink, searchKeywords == nil {
            return (subredditPermalink as NSString).appendingPathComponent("\(self.sortType.rawValue).json")
        } else if let multireddit = self.subreddit as? Multireddit, let author = multireddit.author, let displayName = multireddit.displayName, searchKeywords == nil {
            return "user/\(author)/m/\(displayName.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))/\(self.sortType.rawValue).json"
        } else if let displayName = displayName, searchKeywords == nil {
            return "r/\(displayName)/\(self.sortType.rawValue).json"
        } else if let subredditPermalink = permalink, self.searchKeywords != nil && self.subreddit?.isPrepopulated == false {
            return (subredditPermalink as NSString).appendingPathComponent("search.json")
        } else if self.searchKeywords != nil {
            return "search.json"
        } else {
            return "\(self.sortType.rawValue).json"
        }
    }
    
    override var apiQueryItems: [URLQueryItem]? {
        let sortContext = self.searchKeywords != nil ? CollectionSortContext.postsSearch: CollectionSortContext.posts
        var items: [URLQueryItem] = [URLQueryItem]()
        
        if let searchKeywords = self.searchKeywords {
            let queryItem: URLQueryItem = URLQueryItem(name: "q", redditQuery: searchKeywords)
            items.append(queryItem)
            
            if self.subreddit != nil && self.subreddit?.isPrepopulated == false {
                let restrictItem = URLQueryItem(name: "restrict_sr", value: "true")
                items.append(restrictItem)
            }
        }
        
        let sortItem: URLQueryItem = URLQueryItem(name: "sort", value: self.sortType.rawValue)
        items.append(sortItem)
        
        if self.sortType.supportsTimeFrame(sortContext) {
            items.append(URLQueryItem(name: "t", value: self.timeFrame.rawValue))
        }
        
        let featureItem: URLQueryItem = URLQueryItem(name: "feature", value: "link_preview")
        items.append(featureItem)
        
        return items
    }
    
    public override init() {
        super.init()
    }
    
    open override func fetchRequest() -> NSFetchRequest<NSManagedObject>? {
        let superFetchRequest = super.fetchRequest()
        
        var predicates = [NSPredicate]()
        if let superPredicate = superFetchRequest?.predicate { predicates.append(superPredicate) }
        if subreddit != nil { predicates.append(NSPredicate(format: "subreddit == %@", subreddit!)) }
        
        superFetchRequest?.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return superFetchRequest
    }
    
    open override func collectionType() -> ObjectCollection.Type {
        return PostCollection.self
    }
    
    open override var sortType: CollectionSortType {
        didSet {
            let sortContext = self.searchKeywords != nil ? CollectionSortContext.postsSearch: CollectionSortContext.posts
            
            if !self.sortType.isSupported(sortContext) {
                print("The sortType \(self.sortType) might not be supported for posts and lead to unwanted behavior")
            }
        }
    }
    
}
