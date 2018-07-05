//
//  DataController.swift
//
//  Created by Robin Speijer on 30-03-15.
//  Copyright (c) 2015 Robin Speijer. All rights reserved.
//

import Foundation
import CoreData

private var _sharedDataControllerInstance = DataController()

extension Notification.Name {
    
    public static let DataControllerExpiredContentDeletedFromContext = Notification.Name(rawValue: "ExpiredContentDeletedFromContextNotification")
    public static let DataControllerPersistentStoreDidChange = Notification.Name(rawValue: "PersistentStoreDidChangeNotification")
    public static let DataControllerFoundDatabaseConflict = Notification.Name(rawValue: "FoundDatabaseConflictNotificationName")
    
}

public final class DataController: NSObject {
    
    // MARK: - Static
    
    static let ExpirationTimeOut: TimeInterval = 60.0 * 60.0 // 1 hour
    static let SubredditTimeOut: TimeInterval = 365 * 24 * 60 * 60 // 1 year
    static let PostMetadataExpirationTimeOut: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    
    open class var shared: DataController {
        return _sharedDataControllerInstance
    }
    
    fileprivate let persitentStoreOptions: [String: AnyObject] = [NSPersistentStoreFileProtectionKey: FileProtectionType.completeUntilFirstUserAuthentication as AnyObject,
                                                                            NSInferMappingModelAutomaticallyOption: NSNumber(value: true as Bool),
                                                                            NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true as Bool)]
    
    public var redditReachability: Reachability? = Reachability(hostname: "reddit.com")
    
    override init() {
        super.init()
        
        //Start checking for reachability of the reddit servers
        do {
            try self.redditReachability?.startNotifier()
        } catch {
            NSLog("Failed to listen for reddit.com reachability")
        }

        let oldStorePath: String = self.applicationDocumentsDirectory.appendingPathComponent("Snoo.sqlite").path
        if FileManager.default.fileExists(atPath: oldStorePath) {
            //Migrate the database to a new location
            self.migrateOldDatabase()
        } else {
            //For testflight beta testers we should clear the database, otherwise addPersistentStoreWithType might fail
            self.clearForVersionChange()
        }
        
        self.privateContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        self.privateContext.persistentStoreCoordinator = self.storeCoordinator!
        
        NotificationCenter.default.addObserver(self, selector: #selector(authenticationSessionsChangedNotification(_: )), name: AuthenticationController.AuthenticationSessionsChangedNotificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open var authenticationController: AuthenticationController? {
        didSet {
            self.updatePersistentStores()
        }
    }
    
    fileprivate func migrateOldDatabase() {
        let oldStoreURL = self.applicationDocumentsDirectory.appendingPathComponent("Snoo.sqlite")
        let oldStorePath: String = oldStoreURL.path
        if FileManager.default.fileExists(atPath: oldStorePath) {
            
            let storeMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: oldStoreURL, options: self.persitentStoreOptions)
            var objectModel = self.objectModel
            if let storeMetadata = storeMetadata, let mergedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: DataController.self)], forStoreMetadata: storeMetadata) {
                objectModel = mergedObjectModel
            }
            
            let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
            do {
                try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: oldStoreURL, options: nil)
                //Make the objectContext
                let objectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
                objectContext.persistentStoreCoordinator = storeCoordinator
                
                //Remove everything except subreddits and subreddit collections
                self.performClear(objectContext)
                try objectContext.save()
                
                //Get the userIdentifier for the new URL
                var userIdentifier: String? = nil
                
                if let currentUserSessionData = UserDefaults.standard.object(forKey: AuthenticationController.CurrentUserSessionKey) as? Data, let currenUserSession = NSKeyedUnarchiver.unarchiveObject(with: currentUserSessionData) as? AuthenticationSession {
                    userIdentifier = currenUserSession.userIdentifier
                }
                
                //Do the migration of the persistent store
                let options = [NSPersistentStoreFileProtectionKey: FileProtectionType.completeUntilFirstUserAuthentication,
                               NSInferMappingModelAutomaticallyOption: NSNumber(value: true as Bool),
                               NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true as Bool)] as [String: Any]
                
                let newStoreURL = self.databaseURLForName(self.databaseNameForUserIdentifier(userIdentifier))
                try storeCoordinator.migratePersistentStore(storeCoordinator.persistentStores[0], to: newStoreURL, options: options, withType: NSSQLiteStoreType)
            } catch {
                print("Error adding persitent store for migration")
            }
        }
        
    }
    
    fileprivate func clearForVersionChange() {
        guard let currentBuildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String, let currentBuild = Int(currentBuildString) else {
            return
        }
        let previousBuild = UserDefaults.standard.integer(forKey: "SnooPreviousAppBuild")
        if previousBuild == 0 || previousBuild <= 289 {
            
            print("Performing clear because of version")
            
            //Get the userIdentifier for the new URL
            var userIdentifier: String? = nil
            
            if let currentUserSessionData = UserDefaults.standard.object(forKey: AuthenticationController.CurrentUserSessionKey) as? Data, let currenUserSession = NSKeyedUnarchiver.unarchiveObject(with: currentUserSessionData) as? AuthenticationSession {
                userIdentifier = currenUserSession.userIdentifier
            }
            
            let storeURL = self.databaseURLForName(self.databaseNameForUserIdentifier(userIdentifier))
            if FileManager.default.fileExists(atPath: storeURL.path) {
                let storeMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: self.persitentStoreOptions)
                var objectModel = self.objectModel
                if let storeMetadata = storeMetadata, let mergedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: DataController.self)], forStoreMetadata: storeMetadata) {
                    objectModel = mergedObjectModel
                }
                
                let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
                do {
                    try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                    //Make the objectContext
                    let objectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
                    objectContext.persistentStoreCoordinator = storeCoordinator
                    
                    //Remove everything except subreddits and subreddit collections
                    self.performClear(objectContext)
                    try objectContext.save()
                } catch {
                    print("Error adding persitent store for migration")
                }
            }
        }
        UserDefaults.standard.set(currentBuild, forKey: "SnooPreviousAppBuild")
    }
    
    fileprivate func performClear(_ objectContext: NSManagedObjectContext) {
        objectContext.performAndWait({
            for fetchRequest in self.clearDeleteRequests() {
                do {
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    try objectContext.execute(deleteRequest)
                } catch {
                    print("Error performing delete request")
                }
            }
        })
    }
    
    fileprivate func clearDeleteRequests() -> [NSFetchRequest<NSFetchRequestResult>] {
        let entities = [Thumbnail.entityName(), MediaObject.entityName(), Content.entityName(), ContentCollection.entityName(), MessageCollection.entityName()]
        let requests = entities.map({ (entityName) -> NSFetchRequest<NSFetchRequestResult> in
            return NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        })
        return requests
    }
    
    // MARK: - Core Data stack
    
    public var privateContext: NSManagedObjectContext!
    
    /// The context for presenting or editing data from the UI. The parent context is a private context, which is connected to the persistent store coordinator.
    open func createMainContext() -> NSManagedObjectContext {
        let mainContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        mainContext.parent = self.privateContext
        return mainContext
    }
    
    fileprivate func databaseNameForUserIdentifier(_ userIdentifier: String?) -> String {
        return userIdentifier ?? "anonymous"
    }
    
    fileprivate func databaseURLForName(_ databaseName: String) -> URL {
        let url = self.applicationDocumentsDirectory.appendingPathComponent(databaseName + ".sqlite")
        return url
    }
    
    fileprivate lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[urls.count - 1] as URL
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            let applicationDocumentsURL = appSupportURL.appendingPathComponent(bundleIdentifier)
            return applicationDocumentsURL
        } else {
            fatalError("Could not create application documents URL")
        }
    }()
    
    fileprivate lazy var objectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let bundle = Bundle(for: DataController.self)
        let modelURL = bundle.url(forResource: "Snoo", withExtension: "momd")
        assert(modelURL != nil, "Could not find Snoo.momd in the Snoo bundle.")
        let model = NSManagedObjectModel(contentsOf: modelURL!)
        assert(model != nil, "Could not instantiate the Core Data model at URL: \(modelURL!)")
        return model!
    }()
    
    fileprivate lazy var storeCoordinator: NSPersistentStoreCoordinator? = {
        // Make sure the application files directory is there
        do {
            try self.ensureApplicationDirectory()
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
        
        // Create the coordinator
        return NSPersistentStoreCoordinator(managedObjectModel: self.objectModel)
    }()
    
    fileprivate func ensureApplicationDirectory() throws {
        let propertiesOpt: [URLResourceKey: Any]?
        var propertiesError: NSError?
        do {
            let keys = [URLResourceKey.isDirectoryKey]
            propertiesOpt = try (self.applicationDocumentsDirectory as NSURL).resourceValues(forKeys: keys)
        } catch let error as NSError {
            propertiesOpt = nil
            propertiesError = error
        }
        
        if let properties = propertiesOpt {
            if (properties[URLResourceKey.isDirectoryKey] as? NSNumber)?.boolValue == false {
                let userInfo: [String: String] = [NSLocalizedDescriptionKey: "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."]
                throw NSError(domain: SnooErrorDomain, code: 404, userInfo: userInfo)
            }
        } else if propertiesError?.code == NSFileReadNoSuchFileError {
            propertiesError = nil
            do {
                try FileManager.default.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                propertiesError = error
            }
        }
        
        if let error = propertiesError {
            throw error
        }
    }
    
    @objc fileprivate func authenticationSessionsChangedNotification(_ notification: Notification) {
        // If there are existing operations in the queue, these are still dependent on the current persistent store. Therefore, update the persistent stores in a block operation at the end of the queue.
        let updateOperation = BlockOperation {
            self.updatePersistentStores()
        }
        //Clear the expired content before switching stores
        let expiredContentOperation = DataController.clearExpiredContentOperation()
        updateOperation.addDependency(expiredContentOperation)
        self.executeOperations([expiredContentOperation, updateOperation], handler: nil)
    }
    
    fileprivate func updatePersistentStores() {
        guard let storeCoordinator: NSPersistentStoreCoordinator = self.storeCoordinator else {
            return
        }
        
        let storeIdentifiers: [String] = storeCoordinator.persistentStores.map({ (store: NSPersistentStore) -> String in
            return store.identifier
        })
        let anonymousIdentifier: String = self.databaseNameForUserIdentifier(nil)
        let currentIdentifier: String = self.databaseNameForUserIdentifier(self.authenticationController?.activeUserIdentifier)
        
        if self.authenticationController?.fetchAllAuthenticationSessions().count == 1 && storeIdentifiers.count == 1 && storeCoordinator.persistentStores.first!.identifier == anonymousIdentifier {
             //We have a new account and we only have the anonymous persistent store. We should just change the URL of the existing persitent store
            let anonymousDatabaseURL = self.databaseURLForName(anonymousIdentifier)
            if let anonymousPersistentStore = storeCoordinator.persistentStore(for: anonymousDatabaseURL) {
                //Update the URL to the new URL
                let currentDatabaseURL = self.databaseURLForName(currentIdentifier)
                storeCoordinator.setURL(currentDatabaseURL, for: anonymousPersistentStore)
                //Update the store identifier
                anonymousPersistentStore.identifier = currentIdentifier
                
            }
        } else {
            
            // Add current persistent store.
            if !storeIdentifiers.contains(currentIdentifier) {
                do {
                    try self.addPersistentStore(currentIdentifier)
                } catch {
                    NSLog("Could not add persistent store: \(error)")
                }
            }
            
            // Remove all other persistent stores.
            storeIdentifiers.forEach({ (identifier) in
                guard identifier != currentIdentifier else {
                    return
                }
                do {
                    try self.removePersistentStore(identifier)
                } catch {
                    NSLog("Could not remove persistent store: \(error)")
                }
            })
        }
        
        NotificationCenter.default.post(name: .DataControllerPersistentStoreDidChange, object: self)
    }
    
    fileprivate func removePersistentStore(_ databaseName: String) throws {
        guard let store = self.storeCoordinator?.persistentStores.first(where: { (store) -> Bool in
            return store.identifier == databaseName
        }) else {
            return
        }
        try self.storeCoordinator?.remove(store)
    }
    
    fileprivate func addPersistentStore(_ databaseName: String) throws {
        let databaseURL = self.databaseURLForName(databaseName)
        let options = [NSPersistentStoreFileProtectionKey: FileProtectionType.completeUntilFirstUserAuthentication,
                       NSInferMappingModelAutomaticallyOption: NSNumber(value: true as Bool),
                       NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true as Bool)] as [String: Any]
        
        do {
            let persistentStore = try self.storeCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: databaseURL, options: options)
            persistentStore?.identifier = databaseName
        } catch let error as NSError {
            NSLog("Incompatible Core Data database found. Removing it...")
            if error.code == 134100 {
                do {
                    try FileManager.default.removeItem(at: databaseURL)

                    // Try again
                    try self.storeCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: databaseURL, options: options)
                    NSLog("Succesfully deleted old database instead of migrating.")
                } catch {
                    fatalError("Core Data migration failed, could not resolve by deleting database.")
                }
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Operation Queues
    
    lazy var networkingQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        queue.name = "nl.madeawkward.snoo.networking"
        queue.qualityOfService = QualityOfService.default
        return queue
    }()
    
    lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "nl.madeawkward.snoo.parsing"
        queue.qualityOfService = QualityOfService.userInitiated
        return queue
    }()
    
    lazy fileprivate var operationCompletionHandlerQueue: DispatchQueue = {
        return DispatchQueue(label: "nl.madeawkward.snoo.operation-completion-handler", attributes: DispatchQueue.Attributes.concurrent)
    }()
    
    lazy fileprivate var operationExecutionHandlerQueue: DispatchQueue = {
        return DispatchQueue(label: "nl.madeawkward.snoo.operation-execution-handler", attributes: DispatchQueue.Attributes.concurrent)
    }()
    
    /// Returns the operations in the queue that return true for the given predicate handler. The order is undefined, because Snoo uses different queues internally.
    open func filterQueue(_ predicate: (Operation) -> Bool) -> [Operation] {
        return (self.networkingQueue.operations + self.operationQueue.operations).filter(predicate)
    }
    
    fileprivate func operationsByAddingAuthentication(_ operations: [Operation]) -> [Operation] {
        var operationsToAdd = operations
        let redditOperations = operations.filter({ $0 is RedditRequest }) as! [RedditRequest]
        if let firstRedditOperation = redditOperations.first {
            let authenticationController = firstRedditOperation.authenticationController
            let authenticationOperations = authenticationController.authenticationOperations()
            
            if let lastAuthenticationOperation = authenticationOperations.last {
                firstRedditOperation.addDependency(lastAuthenticationOperation)
            }
            
            operationsToAdd.insert(contentsOf: authenticationOperations, at: 0)
        }
        return operationsToAdd
    }
    
    open func executeOperations(_ operations: [Operation], handler: ((Error?) -> Void)?) {
        
        let allOperations = self.operationsByAddingAuthentication(operations)
        let networkOperations = allOperations.filter({ $0 is DataRequest })
        let otherOperations = allOperations.filter({ !($0 is DataRequest) })
        
        let dispatchGroup = DispatchGroup()
        
        var errors = [Error]()
        
        if networkOperations.count > 0 {
            dispatchGroup.enter()
            self.addOperations(networkOperations, toQueue: self.networkingQueue, handler: { (error) -> Void in
                if let error = error {
                    errors.append(error)
                }
                dispatchGroup.leave()
            })
        }
        
        if otherOperations.count > 0 {
            dispatchGroup.enter()
            self.addOperations(otherOperations, toQueue: self.operationQueue, handler: { (error) -> Void in
                if let error = error {
                    errors.append(error)
                }
                dispatchGroup.leave()
            })
        }
        
        dispatchGroup.notify(queue: self.operationCompletionHandlerQueue, execute: {
            if errors.count > 0 {
                handler?(errors.first!)
            } else {
                handler?(nil)
            }
        })
    }
    
    fileprivate func addOperations(_ operations: [Operation], toQueue queue: OperationQueue, handler: ((Error?) -> Void)?) {
        self.operationExecutionHandlerQueue.async { () -> Void in
           queue.addOperations(operations, waitUntilFinished: true)
            
            var error: Error?
            for operation in operations {
                if let dataOperation = operation as? DataOperation, error == nil {
                    error = dataOperation.error
                }
                if let requestOperation = operation as? DataRequest, error == nil {
                    error = requestOperation.error
                }
            }
            handler?(error)
        }
    }
    
    open func executeAndSaveOperations(_ operations: [Operation], context: NSManagedObjectContext = DataController.shared.privateContext, handler: ((Error?) -> Void)?) {
        let saveOperations = persistentSaveOperations(context)
        if let lastOperation = operations.last {
            saveOperations.first?.addDependency(lastOperation)
        }
        executeOperations(operations + saveOperations, handler: handler)
    }
    
    /// Cancels all the current operations, waits for them to complete and then calls the completion handler
    ///
    /// - Parameter completionHandler: The handler being called when all cancelled operations have finished
    open func cancelAllOperations(completionHandler: (() -> Void)?) {
        self.networkingQueue.cancelAllOperations()
        self.operationQueue.cancelAllOperations()
        DispatchQueue.global(qos: .userInitiated).async {
            self.networkingQueue.waitUntilAllOperationsAreFinished()
            self.operationQueue.waitUntilAllOperationsAreFinished()
            completionHandler?()
        }
    }
    
    open func persistentSaveOperations(_ context: NSManagedObjectContext) -> [SaveOperation] {
        let saveOperation = SaveOperation()
        saveOperation.objectContext = context
        
        if context.parent == nil {
            return [saveOperation]
        } else {
            let parentOperations = persistentSaveOperations(context.parent!)
            parentOperations.first?.addDependency(saveOperation)
            return [saveOperation] + parentOperations
        }
    }
    
    internal func saveContext(_ context: NSManagedObjectContext) throws {
        var thrownError: Error?
        context.performAndWait({ () -> Void in
            context.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
            if context.hasChanges {
                do {
                    try context.save()
                } catch let error as NSError {
                    NSLog("Could not resolve conflicts while saving: %@", error)
                    if error.code == 1555 || error.code == -1555 {
                        NotificationCenter.default.post(name: .DataControllerFoundDatabaseConflict, object: error)
                    }
                    thrownError = error
                } catch {
                    fatalError()
                }
            }
        })
        
        if let error = thrownError {
            throw error
        }
    }
    
    // MARK: - Clearing
    
    open class func clearAllObjectsOperation(_ context: NSManagedObjectContext = DataController.shared.privateContext) -> Operation {
        let deleteOperation = BatchDeleteOperation()
        deleteOperation.onlyClearExpiredContent = false
        deleteOperation.objectContext = context
        return deleteOperation
    }
    
    open class func clearExpiredContentOperation(_ context: NSManagedObjectContext = DataController.shared.privateContext) -> Operation {
        let deleteOperation = BatchDeleteOperation()
        // Only clear objects with an expiration date, and don't clear user objects.
        deleteOperation.onlyClearExpiredContent = true
        deleteOperation.objectContext = context
        deleteOperation.completionBlock = { () -> Void in
            NotificationCenter.default.post(name: .DataControllerExpiredContentDeletedFromContext, object: context)
        }
        return deleteOperation
    }
    
}
