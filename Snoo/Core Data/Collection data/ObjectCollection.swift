//
//  ObjectCollection.swift
//  Snoo
//
//  Created by Robin Speijer on 10-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public enum CollectionSortContext {
    case posts
    case postsSearch
    case comments
}

public enum CollectionSortType: String {
    case none = ""
    case hot = "hot" //Supported: Posts
    case new = "new" //Supported: Posts, Search Posts, Comments
    case controversial = "controversial" //Supported: Posts, Comments
    case gilded = "gilded" //Supported: Posts
    case rising = "rising" //Supported: Posts
    case top = "top" //Supported: Posts, Search Posts, Comments
    case relevance = "relevance" //Supported: Search Posts
    case comments = "comments" //Supported: Search Posts
    case best = "confidence" //Supported: Comments
    case qa = "qa" //Supported: Comments
    case old = "old" //Supported: Comments
    
    public static func defaultSortType (_ context: CollectionSortContext) -> CollectionSortType {
        switch context {
        case .posts:
            return .hot
        case .comments:
            return .best
        case .postsSearch:
            return .relevance
        }
    }
    
    public func supportsTimeFrame(_ context: CollectionSortContext) -> Bool {
        if context == CollectionSortContext.postsSearch {
            let types: [CollectionSortType] = [.relevance, .comments, .new, .top]
            return types.contains(self)
        } else {
            let types: [CollectionSortType] = [.controversial, .top, .relevance, .comments]
            return types.contains(self)
        }
        
    }
    
    public func isSupported(_ context: CollectionSortContext) -> Bool {
        switch context {
        case .comments:
            let types: [CollectionSortType] = [.none, .hot, .new, .controversial, .top, .best, .qa, .old]
            return types.contains(self)
        case .postsSearch:
            let types: [CollectionSortType] = [.none, .relevance, .comments, .new, .top]
            return types.contains(self)
        case .posts:
            let types: [CollectionSortType] = [.none, .hot, .new, .controversial, .gilded, .rising, .top]
            return types.contains(self)
        }
    }
}

public enum CollectionTimeFrame: String {
    case allTime = "all"
    case thisHour = "hour"
    case thisWeek = "week"
    case thisMonth = "month"
    case thisYear = "year"
    case today = "day"
    
    public static var defaultTimeFrame: CollectionTimeFrame {
        return .allTime
    }
}

@objc(ObjectCollection)
open class ObjectCollection: NSManagedObject {

    func configureQuery(_ query: CollectionQuery) {
        self.sortType = query.sortType.rawValue
        self.expirationDate = Date(timeIntervalSinceNow: DataController.ExpirationTimeOut)
        self.contentPredicate = query.contentPredicate?.predicateFormat
    }

    class func entityName() -> String {
        return "ObjectCollection"
    }
}
