//
//  UIViewController+State.swift
//  beam
//
//  Created by Rens Verhoeven on 29-10-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import CoreData
import Snoo

enum BeamViewControllerLoadingState {
    case loading
    case empty
    case noInternetConnection
    case noAccess
    case populated
}

/**
 This protocol (extension) reduces the amount of code needed to present a collection of data to the user. The required methods or properties to implement this loading protocol are:
 
 - CollectionItem type alias
 - content
 - emptyView
 - defaultEmptyViewType
 
*/
protocol BeamViewControllerLoading: class {
    
    // MARK: Required
    
    /// The type of the items that are being loaded and displayed to the user.
    associatedtype CollectionItem: AnyObject
    
    /// The collectionController that is being used for the loading
    var collectionController: CollectionController { get }
    
    /// The content array to be displayed to the user.
    var content: [CollectionItem]? { get set }
    
    /// If the content should be reloaded when a request for content is started by a view controller, but is not granted because the expire date hasn't been reached yet.
    /// This can be used to make sure `content` isn't set when it's not wanted. This is used for instance in the subreddits view to make sure the
    /// Content is not being reparsed into the sections because doing so takes a bit of time and can cause animations to slow down
    /// Especially when this is called in viewWillAppear.
    var shouldReloadContentOnStartFetching: Bool { get }
    
    /// The loading state. The empty view state is dependent on this. To customize this translation, override the emptyViewTypeForState function.
    var loadingState: BeamViewControllerLoadingState { get set }
    
    /// The empty view for the view controller. This will be set by the protocol extension, so be sure to implement didSet. You can assign a block for the button in the empty view in the didSet.
    var emptyView: BeamEmptyView? { get set }
    
    /// The default EmptyViewType that is being used for the empty view.
    var defaultEmptyViewType: BeamEmptyViewType { get }
    
    // MARK: Implemented, possible for overriding:
    
    /// Translates the given ordered set into an array of CollectionItems.
    func contentFromList(_ list: NSOrderedSet?) -> [CollectionItem]
    
    /// Gets the correct empty view type according to the given loading state.
    func emptyViewTypeForState(_ state: BeamViewControllerLoadingState) -> BeamEmptyViewType
    
    func shouldShowLoadingView() -> Bool
    
    /// Returns true of the collection should be fetched. The default implementation is to check the collections isCollectionExpired property.
    func shouldFetchCollection(respectingExpirationDate respectExpirationDate: Bool) -> Bool
    
    /// Presents a loading error to the user. If NoticeHandling is implemented, this is used by default. Otherwise, a UIAlertController is used.
    func presentLoadingError(_ error: Error)
    
    // MARK: Required to call
    
    /// When the fetch has been started, call this method. This will change the loading state and update the empty view.
    func handleCollectionControllerFetching()
    
    /// Call this in the fetch completion block. This will set the content and empty view.
    func handleCollectionControllerResponse(_ error: Error?)
    
    /// Sets the correct empty view, regarding to the loading state.
    func updateEmptyView()
    
}

// MARK: -

extension BeamViewControllerLoading where Self: UIViewController {
    
    /// If the content should be reloaded when a request for content is started by a view controller, but is not granted because the expire date hasn't been reached yet.
    /// This can be used to make sure `content` isn't set when it's not wanted. This is used for instance in the subreddits view to make sure the
    /// Content is not being reparsed into the sections because doing so takes a bit of time and can cause animations to slow down
    /// Especially when this is called in viewWillAppear.
    var shouldReloadContentOnStartFetching: Bool {
        return true
    }

    func presentLoadingError(_ error: Error) {
        
        let message: String!
        var messageType = "posts"
        if self.collectionController.query is SubredditsCollectionQuery {
            messageType = "subreddits"
        } else if self.collectionController.query is MultiredditCollectionQuery {
            messageType = "multireddits"
        }
        let nsError = error as NSError
        if nsError.code == NSURLErrorNotConnectedToInternet && nsError.domain == NSURLErrorDomain {
            message = AWKLocalizedString("error-loading-\(messageType)-internet")
        } else {
            message = AWKLocalizedString("error-loading-\(messageType)")
        }
        
        if let selfNoticing = self as? NoticeHandling {
            selfNoticing.presentErrorMessage(message)
        } else {
            let alert = BeamAlertController(title: message, message: nil, preferredStyle: UIAlertControllerStyle.alert)
            alert.addCloseAction()
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func handleCollectionControllerResponse(_ error: Error?) {
        UIApplication.stopNetworkActivityIndicator(for: self)
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            self.content = self.contentWithCollectionID(self.collectionController.collectionID)
            
            if let error = error {
                self.presentLoadingError(error)
            }
            
            self.updateLoadingState()
        })
    }
    
    func handleCollectionControllerFetching() {
        guard AppDelegate.shared.cherryController.searchTermAllowed(term: self.collectionController.query?.searchKeywords) else {
            self.loadingState = BeamViewControllerLoadingState.empty
            
            self.updateEmptyView()
            return
        }
        
        UIApplication.startNetworkActivityIndicator(for: self)
        
        self.loadingState = .loading
        if self.shouldReloadContentOnStartFetching {
            self.updateContent()
        }
    }
    
    func startCollectionControllerFetching(respectingExpirationDate respectExpirationDate: Bool = false, overwrite: Bool = false) {
        //If the query is missing the view is still loading. Like in the case of a profile
        guard let query = self.collectionController.query else {
            self.loadingState = .loading
            self.updateEmptyView()
            return
        }
        
        guard AppDelegate.shared.cherryController.searchTermAllowed(term: query.searchKeywords) else {
                self.loadingState = BeamViewControllerLoadingState.empty
                
                self.updateEmptyView()
                return
        }

        guard query.requiresAuthentication == false || (query.requiresAuthentication == true && AppDelegate.shared.authenticationController.isAuthenticated == true) else {
            self.loadingState = .noAccess
            self.updateEmptyView()
            return
        }
        
        if self.shouldFetchCollection(respectingExpirationDate: respectExpirationDate) && self.collectionController.status != .fetching {
            self.collectionController.startInitialFetching(overwrite) { [weak self] (_, error) -> Void in
                self?.handleCollectionControllerResponse(error)
            }
            self.handleCollectionControllerFetching()
        } else {
            //Only reload the content if allowed or actually needed (because there is no previous content)
            if self.shouldReloadContentOnStartFetching || self.content == nil || (self.content?.count ?? 0) < 2 {
                self.updateContent()
            }
        }
    }
    
    /**
     Cancel the requests made by the view controller and show an empty state if the content is not loaded.
     */
    func cancelCollectionControllerFetching() {
        UIApplication.stopNetworkActivityIndicator(for: self)
        self.collectionController.cancelFetching()
        if self.content?.count == 0 {
            self.loadingState = .empty
            self.updateEmptyView()
        }
        
    }
    
    func shouldFetchCollection(respectingExpirationDate respectExpirationDate: Bool) -> Bool {
        return (!respectExpirationDate || self.collectionController.isCollectionExpired != false)
    }
    
    func updateContent() {
        if Thread.isMainThread {
            self.content = self.contentWithCollectionID(self.collectionController.collectionID)
            self.updateLoadingState()
        } else {
            DispatchQueue.main.async { () -> Void in
                self.content = self.contentWithCollectionID(self.collectionController.collectionID)
                self.updateLoadingState()
            }
        }
    }
    
    fileprivate func updateLoadingState() {
        
        if !self.shouldShowLoadingView() {
            self.loadingState = .populated
        } else if self.collectionController.status == .fetching {
            self.loadingState = .loading
        } else if let error = self.collectionController.error as NSError?, self.collectionController.status == .error {
            if error.code == 403 {
                self.loadingState = .noAccess
            } else {
                self.loadingState = .noInternetConnection
            }
        } else {
            self.loadingState = .empty
        }
        
        self.updateEmptyView()
    }
    
    func updateEmptyView() {
        self.emptyView = self.emptyViewForState(self.loadingState)
    }
    
    func contentFromList(_ list: NSOrderedSet?) -> [CollectionItem] {
        return (list?.array as? [CollectionItem]) ?? [CollectionItem]()
    }
    
    func collectionWithID(_ collectionID: NSManagedObjectID?) -> ObjectCollection? {
        let context: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
        var collection: ObjectCollection?
        
        context.performAndWait { () -> Void in
            do {
                if let collectionID = collectionID, let object = try context.existingObject(with: collectionID) as? ObjectCollection {
                    collection = object
                }
            } catch {
                AWKDebugLog("Error getting ObjectCollection: %@", (error as NSError))
            }
        }
        
        return collection
    }
    
    func contentWithCollectionID(_ collectionID: NSManagedObjectID?) -> [CollectionItem] {
        let context: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
        var content = [CollectionItem]()
        
        context?.performAndWait { () -> Void in
            do {
                if let collectionID = collectionID, let collection = try context.existingObject(with: collectionID) as? ObjectCollection, let objects = collection.objects {
                    content += self.contentFromList(objects)
                } else {
                    content += self.contentFromList(nil)
                }
            } catch {
                    AWKDebugLog("Error getting content: %@", (error as NSError))
            }
            
        }
        
        return content
    }
    
    fileprivate func emptyViewForState(_ state: BeamViewControllerLoadingState) -> BeamEmptyView? {
        
        let emptyViewType = self.emptyViewTypeForState(state)
        
        switch state {
        case .populated:
            return nil
        case .loading:
            if self.shouldShowLoadingView() {
                let emptyBackgroundView = BeamEmptyView.emptyView(emptyViewType, frame: self.view.bounds)
                emptyBackgroundView.frame = self.view.bounds
                return emptyBackgroundView
            } else {
                return nil
            }
        case .noInternetConnection:
            let emptyBackgroundView = BeamEmptyView.emptyView(emptyViewType, error: self.collectionController.error, frame: self.view.bounds)
            emptyBackgroundView.frame = self.view.bounds
            emptyBackgroundView.buttonHandler = {(button) -> Void in
                self.startCollectionControllerFetching(respectingExpirationDate: false)
            }
            return emptyBackgroundView
        default:
            let emptyBackgroundView = BeamEmptyView.emptyView(emptyViewType, frame: self.view.bounds)
            emptyBackgroundView.frame = self.view.bounds
            return emptyBackgroundView
        }
    }
    
    func shouldShowLoadingView() -> Bool {
        return (self.content?.count ?? 0) == 0
    }
    
    func emptyViewTypeForState(_ state: BeamViewControllerLoadingState) -> BeamEmptyViewType {
        switch state {
        case .loading:
            return BeamEmptyViewType.Loading
        case .noInternetConnection:
            return BeamEmptyViewType.Error
        case .noAccess:
            return BeamEmptyViewType.MultiredditNoAccess
        default:
            if let characters = self.collectionController.query?.searchKeywords, characters.count > 0 {
                return BeamEmptyViewType.SearchNoResults
            }
            return self.defaultEmptyViewType
        }
    }
    
}
