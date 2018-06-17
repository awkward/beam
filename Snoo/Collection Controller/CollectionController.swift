//
//  CollectionController.swift
//  Snoo
//
//  Created by Robin Speijer on 11-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData

/**
The status of what the collection controller is doing.
*/
public enum CollectionControllerStatus {
    /// The controller is doing nothing and is in it's resting state and has no data in memory. The collection property is nil.
    case idle
    /// The controller is currently fetching the Reddit API or parsing that data.
    case fetching
    /// The controller has finished fetching data and has parsed data into memory. The collection property is not nil.
    case inMemory
    /// When fetching or parsing fails, the status is Error. The error property is not nil, but it is possible that the collection property is still non-nil.
    case error
}

public typealias CollectionControllerHandler = ((NSManagedObjectID?, Error?) -> Void)

public protocol CollectionControllerDelegate: class {
    
    // The collection content has been updated by either a fetch or Core Data change
    func collectionController(_ controller: CollectionController, collectionDidUpdateWithID objectID: NSManagedObjectID?)
    
    func collectionController(_ controller: CollectionController, didUpdateStatus newStatus: CollectionControllerStatus)
    
    // Asks the delegate to automatically fetch more content after the recent reload. Default implementation: false
    func collectionControllerShouldFetchMore(_ controller: CollectionController) -> Bool
    
}

extension CollectionControllerDelegate {
    
    public func collectionController(_ controller: CollectionController, collectionDidUpdateWithID objectID: NSManagedObjectID?) {
        
    }
    
    public func collectionController(_ controller: CollectionController, didUpdateStatus newStatus: CollectionControllerStatus) {
        
    }
    
    public func collectionControllerShouldFetchMore(_ controller: CollectionController) -> Bool {
        return false
    }
    
}

/**
The CollectionController fetches objects from either the local database and the Reddit API. The objects are presented as an ObjectCollection (or a subclass of it), which will be controlled by this object.
*/
public final class CollectionController: NSObject {
    
    /// The notification name for the notification that is being sent whenever the status for the collection controller changes.
    open static let StatusChangedNotificationName = NSNotification.Name(rawValue: "collection-controller-status-changed")
    
    // MARK: - Public properties
    open var managedObjectContext: NSManagedObjectContext
    
    /// The authentication controller used for requests to the Reddit API. This is required and asked in the required initializer.
    open var authenticationController: AuthenticationController
    
    /// The delegate to inform about data changes and that is asked about whether to continue fetching date.
    open weak var delegate: CollectionControllerDelegate?
    
    /// The query to execute on the Reddit API. This will define what subreddit you fetch, what sorting you will get, etc. If you set this query, the local cache will directly be retreived. Up-to-date content need to be fetched manually.
    open var query: CollectionQuery? {
        didSet {
            query?.collectionController = self
            do {
                self.cancelFetching()
                
                if let query = query {
                    self.collectionID = try fetchLocalCollection(query)
                } else {
                    self.collectionID = nil
                }
            } catch {
                NSLog("Could not fetch local collection: \(error)")
                self.collectionID = nil
            }
        }
    }
    
    /// The status of what the controller is doing.
    open var status = CollectionControllerStatus.idle {
        didSet {
            self.delegate?.collectionController(self, didUpdateStatus: status)
            NotificationCenter.default.post(name: CollectionController.StatusChangedNotificationName, object: self)
        }
    }
    
    /// If the status if the controller is .Error, this error property has been set by the controller. This way you can communicate the reason of the failure to the user.
    open var error: Error?
    
    /// The collection that is controlled by this controller.
    open var collectionID: NSManagedObjectID? {
        didSet {
            self.delegate?.collectionController(self, collectionDidUpdateWithID: collectionID)
        }
    }
    
    open var filteredObjectIDs: [NSManagedObjectID]?
    
    /// Whether or not the collection is expired. If so, the content should be reloaded. If this property is nil if there is no collection or the collection has no expiration date.
    open var isCollectionExpired: Bool? {
        var expirationDate: Date?
        if let collectionID = self.collectionID {
            self.managedObjectContext.performAndWait { () -> Void in
                do {
                    expirationDate = (try self.managedObjectContext.existingObject(with: collectionID) as? ObjectCollection)?.expirationDate as Date?
                } catch {
                    return
                }
            }
        }
        
        if let expirationDate = expirationDate {
            return (expirationDate as NSDate).earlierDate(Date()) == expirationDate
        }
        
        return nil
    }
    
    // MARK: - Private properties
    
    fileprivate var requests = NSMutableSet(capacity: 2)
    
    /// The NSURLSession for the controller. This way, the controller has it's own request queue. We can still think about making this public or using a shared session within Snoo to support a shared queue with other controllers.
    fileprivate var urlSession: URLSession
    
    /// The after identifier used by the Reddit API, to support batching
    fileprivate var after: String?
    
    /// The before identifier used by the Reddit API, to support batching
    fileprivate var before: String?
    
    // MARK: - (de)init
    
    public required init(authentication: AuthenticationController, context: NSManagedObjectContext) {
        self.managedObjectContext = context
        self.authenticationController = authentication
        self.urlSession = authenticationController.userURLSession
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionController.userDidChange(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionController.objectContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionController.objectContextObjectsDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context)
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionController.persistentStoreDidChange(_: )), name: .DataControllerPersistentStoreDidChange, object: DataController.shared)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.urlSession.delegateQueue.cancelAllOperations()
    }
    
    // MARK: - Fetching
    
    @objc fileprivate func persistentStoreDidChange(_ notification: Notification) {
        self.collectionID = nil
        self.filteredObjectIDs = nil
    }
    
    @objc fileprivate func objectContextDidSave(_ notification: Notification) {
        var changedObjects = Set<NSManagedObject>()
        if let insertedObjects = (notification as NSNotification).userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            changedObjects.formUnion(insertedObjects)
        }
        if let updatedObjects = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            changedObjects.formUnion(updatedObjects)
        }
        if let deletedObjects = (notification as NSNotification).userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> {
            changedObjects.formUnion(deletedObjects)
        }
        
        if let collectionID = self.collectionID {
            let collections = changedObjects.filter({ $0 is ObjectCollection })
            if collections.map({ ($0 as! ObjectCollection).objectID }).contains(collectionID) {
                self.delegate?.collectionController(self, collectionDidUpdateWithID: collectionID)
            }
        }
    }
    
    @objc fileprivate func objectContextObjectsDidChange(_ notification: Notification) {
        guard notification.object as? NSManagedObjectContext == self.managedObjectContext else {
            return
        }
        
        if let collectionID = self.collectionID, let query = self.query, let contentPredicate = query.compoundContentPredicate {
            if let updatedObjects = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                let updatedSyncObjects = updatedObjects.compactMap { (object) -> SyncObject? in
                    return object as? SyncObject
                }
                let collection = self.managedObjectContext.object(with: collectionID) as? ObjectCollection
                if collection?.objects?.contains( where: { updatedSyncObjects.contains($0 as! SyncObject) }) == true {
                    collection?.objects = collection?.objects?.filtered(using: contentPredicate)
                }
            }
        }
    }
    
    @objc fileprivate func userDidChange(_ notification: Notification) {
        self.urlSession = self.authenticationController.userURLSession
    }
    
    /**
    Starts fetching objects initially from either Core Data and from the Reddit API. This will create an object collection and set this on the collection property of the class. The status property will be updated on the controller, but you can use the handler to be notified when the controller is done.
    
    - parameter overwrite: Whether to delete the existing collection for this CollectionController
    - parameter handler: The completion handler to be executed when the initial fetching of the object collection is done. The handler will be called on the object context queue.
    */
    open func startInitialFetching(_ overwrite: Bool = false, handler: CollectionControllerHandler?) {
        // Delete the old collection when overwriting. The content can be totally different.
        if let collectionID = self.collectionID, overwrite == true {
            let deleteOperation = BlockOperation(block: { () -> Void in
                self.managedObjectContext.performAndWait({ () -> Void in
                    let collection = self.managedObjectContext.object(with: collectionID) as! ObjectCollection
                    self.managedObjectContext.delete(collection)
                })
            })
            DataController.shared.executeAndSaveOperations([deleteOperation], context: self.managedObjectContext, handler: nil)
            self.collectionID = nil
        }
        
        // Only start if it's no search or if there are search characters
        if let query = self.query, query.searchKeywords == nil || query.searchKeywords?.count ?? 0 > 0 {
            if overwrite {
                do {
                    self.collectionID = try self.fetchLocalCollection(query)
                } catch {
                    self.collectionID = nil
                }
            }
            
            self.startFetching(nil, handler: handler)
        } else {
            if self.query == nil {
                NSLog("Triggered collection fetch without query")
            }
            
            self.collectionID = nil
            
            self.managedObjectContext.perform({ () -> Void in
                handler?(nil, nil)
            })
        }
    }
    
    open func startFetchingMore(_ handler: CollectionControllerHandler?) {
        if let after = self.after {
            self.startFetching(after, handler: handler)
        } else {
            handler?(nil, NSError.snooError(204, localizedDescription: "No more content available"))
        }
    }
    
    open func cancelFetching() {
        for request in self.requests {
            if let request = request as? RedditCollectionRequest {
                request.cancel()
            }
        }
        
        self.requests.removeAllObjects()
        if self.collectionID == nil {
            self.status = .idle
        }
    }
    
    /// This property can be used to add some post-parsing operations that will be executed before saving the private context. The value should be a block that returns an array of operations and will be called before executing all the fetch operations. The dependency of the first operation in this array will be set to a CollectionParsingOperation, which contains the resulting object collection.
    open var postProcessOperations: (() -> [Operation])?
    
    fileprivate func startFetching(_ after: String?, handler: CollectionControllerHandler?) {
        
        guard self.query != nil else {
            handler?(nil, NSError.snooError(400, localizedDescription: "Collection Query missing"))
            return
        }
        
        guard (self.query!.requiresAuthentication == true && self.authenticationController.isAuthenticated) || !self.query!.requiresAuthentication else {
            handler?(nil, NSError.snooError(401, localizedDescription: "Authorization required"))
            return
        }
        
        self.error = nil
        self.status = .fetching
        
        var operations = [Operation]()
        
        let collectionRequest = RedditCollectionRequest(query: self.query!, authenticationController: authenticationController)
        collectionRequest.urlSession = self.authenticationController.userURLSession
        collectionRequest.after = after
        operations.append(collectionRequest)
        
        let parseOperation = CollectionParsingOperation(query: self.query!)
        parseOperation.objectContext = DataController.shared.privateContext
        parseOperation.shouldDeleteMissingMemoryObjects = after == nil
        parseOperation.objectContext?.performAndWait { () -> Void in
            if let collectionID = self.collectionID, after != nil {
                parseOperation.objectCollection = parseOperation.objectContext?.object(with: collectionID) as? ObjectCollection
            }
        }
        
        parseOperation.addDependency(collectionRequest)
        operations.append(parseOperation)
        
        if let postProcessOperations = self.postProcessOperations?() {
            var previousPostOperation: Operation? = nil
            for postOperation in postProcessOperations {
                postOperation.addDependency(parseOperation)
                if let previousPostOperation = previousPostOperation {
                    postOperation.addDependency(previousPostOperation)
                }
                previousPostOperation = postOperation
                operations.append(postOperation)
            }
        }
        
        DataController.shared.executeAndSaveOperations(operations) { [weak self] (error: Error?) -> Void in
            self?.filteredObjectIDs = parseOperation.filteredObjects?.map({ $0.objectID })
            
            //Only set the before and after if error is nil, otherwise we are going to have a very bad time
            if error == nil {
                self?.before = parseOperation.before
                self?.after = parseOperation.after
            }
            
            if let error = error {
                self?.error = error
            } else if let resultingCollection = parseOperation.objectCollection {
                assert(!resultingCollection.objectID.isTemporaryID)
                
                self?.collectionID = resultingCollection.objectID
                
                // If the updated collection is already registered for this collection controller, it should be refreshed to reflect its new content.
                self?.managedObjectContext.performAndWait({ () -> Void in
                    if let collection = self?.managedObjectContext.registeredObject(for: resultingCollection.objectID) {
                        self?.managedObjectContext.refresh(collection, mergeChanges: true)
                    }
                })
                
            } else if parseOperation.isCancelled == false {
                //If the operation was cancelled, just continue. If it wan't cancelled we did have an serious error
                fatalError("Missing error or object collection")
            }
            
            if self?.error != nil {
                self?.status = .error
            } else if self?.collectionID != nil {
                self?.status = .inMemory
            } else {
                self?.status = .idle
            }
            
            if self?.query === parseOperation.query {
                if self?.moreContentAvailable == true && self != nil && self?.delegate?.collectionControllerShouldFetchMore(self!) == true {
                    self?.startFetchingMore(handler)
                } else {
                    handler?(self?.collectionID, self?.error)
                }
            }
        }
    }
    
    fileprivate func fetchLocalCollection(_ query: CollectionQuery) throws -> NSManagedObjectID? {
        
        if let fetchRequest = query.fetchRequest() {
            var result: ObjectCollection?
            var thrownError: Error?
            
            DataController.shared.privateContext.performAndWait({ () -> Void in
                do {
                    result = try self.managedObjectContext.fetch(fetchRequest).first as? ObjectCollection
                    if result?.managedObjectContext == nil {
                        result = nil
                    }
                } catch {
                    thrownError = error
                }
            })
            
            if thrownError != nil {
                throw thrownError!
            }
            
            return result?.objectID
        } else {
            return nil
        }
    }
    
    open var moreContentAvailable: Bool {
        return self.after != nil && self.status != .fetching && self.status != .idle
    }
    
    open func clear() {
        collectionID = nil
    }
    
}
