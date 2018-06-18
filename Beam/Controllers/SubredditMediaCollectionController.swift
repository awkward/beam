//
//  MediaObjectController.swift
//  beam
//
//  Created by David van Leeuwen on 20/08/15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

protocol SubredditMediaCollectionControllerDelegate: class {
    
    func mediaCollectionController(_ controller: SubredditMediaCollectionController, didChangeCollection collection: [Post]?)
    func mediaCollectionController(_ controller: SubredditMediaCollectionController, shouldFetchMoreForCollection collection: [Post]?) -> Bool
    
    func mediaCollectionController(_ controller: SubredditMediaCollectionController, statusDidChange status: CollectionControllerStatus)
    
    func mediaCollectionController(_ controller: SubredditMediaCollectionController, filterCollection collection: [Post]) -> [Post]
    
}

extension SubredditMediaCollectionControllerDelegate {
    
    func mediaCollectionController(_ controller: SubredditMediaCollectionController, filterCollection collection: [Post]) -> [Post] {
        return collection
    }
    
}

/// A media controller for a certain subreddit. It fetches all media items from the specified subreddit stream using a CollectionController. The object that is being used is a Post, as each post should have an image for in the media view. Albums should be displayed as a stack.

class SubredditMediaCollectionController: NSObject {
    
    fileprivate var KVOContext = 0
    
    weak var delegate: SubredditMediaCollectionControllerDelegate?
    
    fileprivate var query: CollectionQuery? {
        get {
            return self.collectionController.query
        }
        set {
            self.collectionController.query = newValue
        }
    }
    
    var collection: [Post]? {
        didSet {
            self.delegate?.mediaCollectionController(self, didChangeCollection: collection)
            if self.moreContentAvailable && self.delegate?.mediaCollectionController(self, shouldFetchMoreForCollection: collection) == true {
                self.fetchMoreContent()
            }
        }
    }
    
    func setSortingType(_ sorting: CollectionSortType, timeFrame: CollectionTimeFrame) {
        let query = PostCollectionQuery()
        query.subreddit = self.subreddit
        query.sortType = sorting
        query.timeFrame = timeFrame
        query.hideNSFWContent = !AppDelegate.shared.authenticationController.userCanViewNSFWContent
        self.query = query
        self.reloadMedia()
    }
    
    var sortType: CollectionSortType? {
        return self.query?.sortType
    }
    
    var timeFrame: CollectionTimeFrame? {
        return (self.query as? PostCollectionQuery)?.timeFrame
    }
    
    var isCollectionExpired: Bool? {
        return self.collectionController.isCollectionExpired
    }
    
    var error: Error? {
        return self.collectionController.error
    }
    
    fileprivate (set) var subreddit: Subreddit?
    
    /// The collection controller that is being used internally for fetching the posts from the database and from Reddit.
    fileprivate var collectionController: CollectionController
    
    deinit {
        self.collectionController.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Creates a SubredditMediaCollectionController using the given subreddit. It will immediately look at the cache and fetch all new images from the CollectionController.
    init(subreddit: Subreddit) {
        self.subreddit = subreddit
        let query = PostCollectionQuery()
        query.subreddit = subreddit
        query.sortType = .hot
        query.timeFrame = .thisMonth
        query.hideNSFWContent = !AppDelegate.shared.authenticationController.userCanViewNSFWContent
        self.collectionController = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        super.init()
        self.query = query
        
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditMediaCollectionController.statusDidChange(_:)), name: CollectionController.StatusChangedNotificationName, object: self.collectionController)
        
        self.collectionController.addObserver(self, forKeyPath: "status", options: [NSKeyValueObservingOptions.new], context: &KVOContext)
        self.collectionController.postProcessOperations = { () -> [Operation] in
            let imagesOperation = StreamImagesOperation()
            imagesOperation.cherryController = AppDelegate.shared.cherryController
            return [imagesOperation]
        }
        
        self.reloadMedia()
    }

    @objc func statusDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.delegate?.mediaCollectionController(self, statusDidChange: self.collectionController.status)
        }
    }
    
    // MARK: - Data
    
    var count: Int {
        return self.collection?.count ?? 0
    }
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> Post? {
        return self.collection?[indexPath.item]
    }
    
    func indexPathForCollectionItem(_ item: Post) -> IndexPath? {
        guard let index = self.collection?.index(where: { (post) -> Bool in
            post == item
        }) else {
            return nil
        }
        return IndexPath(item: index, section: 0)
    }
    
    func cancelFetching() {
        self.collectionController.cancelFetching()
    }
    
    var moreContentAvailable: Bool {
        if self.collectionController.status == .idle {
            return true
        }
        return self.collectionController.moreContentAvailable
    }
    
    func fetchInitialContent() {
        self.collectionController.startInitialFetching { (_, _) -> Void in
            let context: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
            context.perform {
                self.reloadMedia()
            }
        }
    }
    
    func fetchMoreContent() {
        self.collectionController.startFetchingMore({ (_, _) -> Void in
            let context: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
            context.perform {
                self.reloadMedia()
            }
        })
    }
    
    /// The loading status for the media collection controller
    var status: CollectionControllerStatus {
        return self.collectionController.status
    }
    
    /// The raw collection of fetched objects. Still needs to be filtered by image presence.
    fileprivate var fetchedObjects: [Post]? {
        if let collectionID = self.collectionController.collectionID {
            let collection = self.collectionController.managedObjectContext.object(with: collectionID) as? ObjectCollection
            return collection?.objects?.array as? [Post]
        }
        return nil
    }
    
    /// Filters the fetchedObjects and replaces the collection property.
    func reloadMedia() {
        if let fetchedObjects: [Post] = self.fetchedObjects {
            var objects: [Post] = fetchedObjects.filter({ (object: Post) -> Bool in
                return object.mediaObjects?.count != 0
            })
            if let delegate: SubredditMediaCollectionControllerDelegate = self.delegate {
                objects = delegate.mediaCollectionController(self, filterCollection: objects)
            }
            self.collection = objects
        } else {
            self.collection = self.fetchedObjects
        }
        
    }
    
}
