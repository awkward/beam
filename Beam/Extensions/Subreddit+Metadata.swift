//
//  Subreddit+Metadata.swift
//  Beam
//
//  Created by Rens Verhoeven on 09-12-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData
import Snoo

enum SubredditMetadataKey: String {
    case StreamSortType = "com.madeawkward.beam.subreddit.streamsortype"
    case MediaSortType = "com.madeawkward.beam.subreddit.mediasortype"
    case CommentsSortType = "com.madeawkward.beam.subreddit.commentsorttype"
    case StreamTimeFrame = "com.madeawkward.beam.subreddit.streamtimeframe"
    case MediaTimeFrame = "com.madeawkward.beam.subreddit.mediatimeframe"
    case FilterKeywords = "com.madeawkward.beam.subreddit.filterkeywords"
    case FilterSubreddits = "com.madeawkward.beam.subreddit.filtersubreddits"
}

extension Subreddit {

    var streamSortType: CollectionSortType {
        get {
            if let sortTypeString = self.metadataValueForKey(SubredditMetadataKey.StreamSortType.rawValue) as? String, let sortType = CollectionSortType(rawValue: sortTypeString) {
                return sortType
            }
            return CollectionSortType.hot
        }
        set {
            self.setMetadataValue(newValue.rawValue, forKey: SubredditMetadataKey.StreamSortType.rawValue)
        }
        
    }
    
    var streamTimeFrame: CollectionTimeFrame {
        get {
            if let sortTypeString = self.metadataValueForKey(SubredditMetadataKey.StreamTimeFrame.rawValue) as? String, let sortType = CollectionTimeFrame(rawValue: sortTypeString) {
                return sortType
            }
            return CollectionTimeFrame.thisMonth
        }
        set {
            self.setMetadataValue(newValue.rawValue, forKey: SubredditMetadataKey.StreamTimeFrame.rawValue)
        }
        
    }
    
    var mediaSortType: CollectionSortType {
        get {
            if let sortTypeString = self.metadataValueForKey(SubredditMetadataKey.MediaSortType.rawValue) as? String, let sortType = CollectionSortType(rawValue: sortTypeString) {
                return sortType
            }
            return CollectionSortType.hot
        }
        set {
            self.setMetadataValue(newValue.rawValue, forKey: SubredditMetadataKey.MediaSortType.rawValue)
        }
        
    }
    
    var mediaTimeFrame: CollectionTimeFrame {
        get {
            if let sortTypeString = self.metadataValueForKey(SubredditMetadataKey.MediaTimeFrame.rawValue) as? String, let sortType = CollectionTimeFrame(rawValue: sortTypeString) {
                return sortType
            }
            return CollectionTimeFrame.thisMonth
        }
        set {
            self.setMetadataValue(newValue.rawValue, forKey: SubredditMetadataKey.MediaTimeFrame.rawValue)
        }
        
    }
    
    var commentsSortType: CollectionSortType {
        get {
            if let sortTypeString = self.metadataValueForKey(SubredditMetadataKey.CommentsSortType.rawValue) as? String, let sortType = CollectionSortType(rawValue: sortTypeString) {
                
                return sortType
            }
            return CollectionSortType.best
        }
        set {
            if newValue.isSupported(CollectionSortContext.comments) {
                self.setMetadataValue(newValue.rawValue, forKey: SubredditMetadataKey.CommentsSortType.rawValue)
            }
        }
    }
    
    var filterKeywords: [String]? {
        get {
            if let filterKeywords: [String] = self.metadataValueForKey(SubredditMetadataKey.FilterKeywords.rawValue) as? [String], filterKeywords.count > 0 {
                return filterKeywords
            }
            return nil
        }
        set {
            if newValue == nil || (newValue?.count)! <= 0 {
                self.removeMetadataValueForKey(SubredditMetadataKey.FilterKeywords.rawValue)
            } else {
                self.setMetadataValue(newValue!, forKey: SubredditMetadataKey.FilterKeywords.rawValue)
            }
        }
    }
    
    var filterSubreddits: [String]? {
        get {
            if let filterSubreddits: [String] = self.metadataValueForKey(SubredditMetadataKey.FilterSubreddits.rawValue) as? [String], filterSubreddits.count > 0 {
                return filterSubreddits
            }
            return nil
        }
        set {
            if newValue == nil || (newValue?.count)! <= 0 {
                self.removeMetadataValueForKey(SubredditMetadataKey.FilterSubreddits.rawValue)
            } else {
                self.setMetadataValue(newValue!, forKey: SubredditMetadataKey.FilterSubreddits.rawValue)
            }
        }
    }

}
