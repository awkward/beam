//
//  StreamViewController.swift
//  beam
//
//  Created by Robin Speijer on 25-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData
import AWKGallery
import TTTAttributedLabel
import CherryKit
import SafariServices
import AVFoundation
import Ocarina

enum BeamStreamSortingType {
    case hot
    case new
    case allTime
    
    func sortType() -> CollectionSortType {
        switch self {
        case .hot:
            return .hot
        case .new:
            return .new
        case .allTime:
            return .top
        }
    }
    
    func timeFrame() -> CollectionTimeFrame {
        return self == .hot ? .thisMonth : .allTime
    }
}

protocol StreamViewControllerDelegate: class {
    
    func streamViewController(_ viewController: StreamViewController, didChangeContent content: [Content]?)
    
}

extension StreamViewControllerDelegate {
    
    func streamViewController(_ viewController: StreamViewController, didChangeContent content: [Content]?) {

    }
}

private enum StreamCellTypeIdentifier: String {
    case Title = "title"
    case TitleWithThumbnail = "titlethumbnail"
    case SelfText = "selftext"
    case Metadata = "metadata"
    case Toolbar = "toolbar"
    case Image = "image"
    case Album = "album"
    case Link = "link"
    case Video = "video"
    case Comment = "comment"
}

class StreamViewController: BeamTableViewController, PostMetadataViewDelegate, BeamViewControllerLoading, MediaObjectsGalleryPresentation {
    
    //The insets to calculate the content rect that is the most visible to the user, this is used to only play gifs that are in this visible rect.
    static fileprivate let visibleContentInset: UIEdgeInsets = UIEdgeInsets(top: 200, left: 0, bottom: 200, right: 0)
    
    @IBOutlet var loadingFooterView: LoaderFooterView!

    var refreshNotification: RefreshNotificationView? {
        didSet {
            if let notificationView = oldValue, self.refreshNotification == nil {
                notificationView.dismiss()
            }
        }
    }
    
    typealias CollectionItem = Content
    
    weak var streamDelegate: StreamViewControllerDelegate?
    
    var collectionController: CollectionController = {
        
        let controller = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
        
        controller.postProcessOperations = { () -> ([Operation]) in
            let operation = StreamImagesOperation()
            operation.cherryController = AppDelegate.shared.cherryController
            return [operation, MarkdownParsingOperation()]
        }
        
        return controller
    }()
    
    var query: CollectionQuery? {
        get {
            return self.collectionController.query
        }
        set {
            self.collectionController.query = newValue
            //Only update if the view is actually displayed
            if self.view.window != nil {
                self.startCollectionControllerFetching()
            }
            
            self.defaultEmptyViewType = BeamEmptyViewType.SubredditNoPosts
        }
    }
    
    //If the view should start fetching on view will appear, this is used in the detail view to prevent a post from loading twice.
    var startsFetchingOnViewWillAppear = true
    
    //Used to make stream work with UISearchController
    var customNavigationController: UINavigationController?

    override var navigationController: UINavigationController? {
        if self.customNavigationController != nil {
            return self.customNavigationController
        }
        return super.navigationController
    }
    
    var subreddit: Subreddit? {
        return (self.collectionController.query as? PostCollectionQuery)?.subreddit
    }
    
    //The currently visible subreddit, used for determening the NSFW overlay and more. In case of the frontpage this subreddit is the frontpage.
    //This property is overwritten in the PostDetailViewController to return the context subreddit
    var visibleSubreddit: Subreddit? {
        return self.subreddit
    }
    
    weak var hidingButtonBarDelegate: HidingButtonBarDelegate?
    
    fileprivate var privateUseCompactViewMode = false {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var useCompactViewMode: Bool {
        get {
            if self.subreddit?.thumbnailViewType ?? UserSettings[.thumbnailsViewType] == ThumbnailsViewType.medium {
                return true
            }
            return self.privateUseCompactViewMode
        }
        set {
            self.privateUseCompactViewMode = newValue
        }
    }

    var defaultEmptyViewType: BeamEmptyViewType = BeamEmptyViewType.SubredditNoPosts
    
    var loadingState = BeamViewControllerLoadingState.empty {
        didSet {
            if self.collectionController.status != .fetching {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    var hasEnteredLoadMoreState = false {
        didSet {
            if self.hasEnteredLoadMoreState == true && oldValue != self.hasEnteredLoadMoreState {
                self.fetchMoreContent()
            }
        }
    }
    
    var emptyView: BeamEmptyView? {
        didSet {
            //If the searchKeywords is nil, the query is not used for a search.
            if let searchKeywords = self.query?.searchKeywords, searchKeywords.count == 0 {
                self.tableView.backgroundView = nil
            } else {
                self.refreshControl?.alpha = (self.emptyView?.emptyType == BeamEmptyViewType.Loading) ? 0: 1
                self.tableView.backgroundView = self.emptyView
            }
        }
    }
    
    fileprivate weak var refreshNotificationTimer: Timer?
    
    internal var galleryMediaObjects: [MediaObject]?
    fileprivate var gallerySourceIndexPath: IndexPath?
    
    fileprivate var urlInformationPrefetcher: OcarinaPrefetcher?
    
    var content: [Content]? {
        didSet {
            let urls: [URL]? = self.content?.compactMap { (content) -> URL? in
                guard let post = content as? Post, let urlString = post.urlString else {
                    return nil
                }
                return URL(string: urlString)
            }
            self.urlInformationPrefetcher?.cancel()
            if let prefetchUrls = urls {
                self.urlInformationPrefetcher = OcarinaPrefetcher(urls: prefetchUrls)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                
                if !(self is PostDetailEmbeddedViewController) {
                    UIView.animate(withDuration: 0.32, animations: { () -> Void in
                        self.tableView.tableFooterView?.frame = CGRect(origin: self.tableView.tableFooterView!.frame.origin, size: CGSize(width: self.tableView.bounds.width, height: 0))
                    }, completion: { (_) -> Void in
                        self.tableView.tableFooterView = nil
                    })
                    self.startRefreshNotificationTimer(self.collection?.expirationDate)
                }
                
                self.streamDelegate?.streamViewController(self, didChangeContent: self.content)
            }
        }
    }
    
    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Register all cells
        self.tableView.register(UINib(nibName: "PostTitlePartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.Title.rawValue)
        self.tableView.register(UINib(nibName: "PostTitleWithThumbnailPartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.TitleWithThumbnail.rawValue)
        self.tableView.register(UINib(nibName: "PostSelfTextPartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.SelfText.rawValue)
        self.tableView.register(UINib(nibName: "PostToolbarPartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.Toolbar.rawValue)
        self.tableView.register(UINib(nibName: "PostCommentPartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.Comment.rawValue)
        self.tableView.register(UINib(nibName: "PostMetaDataPartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.Metadata.rawValue)
        self.tableView.register(UINib(nibName: "PostURLPartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.Link.rawValue)
        self.tableView.register(UINib(nibName: "PostVideoURLPartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.Video.rawValue)
        self.tableView.register(UINib(nibName: "PostImageCollectionPartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.Album.rawValue)
        self.tableView.register(UINib(nibName: "PostImagePartCell", bundle: nil), forCellReuseIdentifier: StreamCellTypeIdentifier.Image.rawValue)
        
        NotificationCenter.default.addObserver(self, selector: #selector(StreamViewController.contextDidSaveNotification(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: AppDelegate.shared.managedObjectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(StreamViewController.userSettingChanged(_:)), name: .SettingsDidChangeSetting, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StreamViewController.postDidChangeHiddenFlag(_:)), name: .PostDidChangeHiddenState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StreamViewController.contentDidDelete(_:)), name: .ContentDidDelete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StreamViewController.postDidChangeSavedState(_:)), name: .ContentDidChangeSavedState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StreamViewController.postSucessfullySubmitted(_:)), name: .PostSubmitted, object: nil)
        
        //Adjust table view
        self.tableView.estimatedRowHeight = 60
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        //Add refresh control
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(StreamViewController.refreshContent(_:)), for: UIControlEvents.valueChanged)
        
        self.registerForPreviewing(with: self, sourceView: self.tableView)
    }
    
    deinit {
        self.cancelRequests()
        if self.refreshNotificationTimer != nil {
            self.refreshNotificationTimer!.invalidate()
            self.refreshNotificationTimer = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Set the audio category for the autoplaying gifs
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            NSLog("Failed to change audio session. Gifs might pause audio.")
        }
        
        self.tableView.reloadData()
        
        if self.refreshNotificationTimer == nil {
            self.startRefreshNotificationTimer(self.collection?.expirationDate)
        }
        
        if self.startsFetchingOnViewWillAppear == true && (self.collectionController.status == .idle || (self.content?.count ?? 0 == 0 && self.collectionController.status != .fetching)) {
            self.startCollectionControllerFetching()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateGifPlayingState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.pauseAllPlayingGifs()
        
        if self.refreshNotificationTimer != nil {
            self.refreshNotificationTimer!.invalidate()
            self.refreshNotificationTimer = nil
        }
    }
    
    // MARK: Data
    
    @objc func contextDidSaveNotification(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            //Update the posts shown when a multireddit changes
            guard let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                let currentMultireddit = self.subreddit as? Multireddit,
                self.collectionController.status == CollectionControllerStatus.inMemory && updatedObjects.contains(currentMultireddit) else {
                return
            }
            self.startCollectionControllerFetching(respectingExpirationDate: false)
        }
    }
    
    @objc func userSettingChanged(_ notification: Notification) {
        if notification.object as? SettingsKeys == SettingsKeys.thumbnailsViewType || notification.object as? SettingsKeys == SettingsKeys.subredditsThumbnailSetting {
            self.useCompactViewMode = self.subreddit?.thumbnailViewType ?? UserSettings[.thumbnailsViewType] == ThumbnailsViewType.medium
        }
    }
    
    @objc func postDidChangeHiddenFlag(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            if let post = notification.object as? Post, post.isHidden.boolValue == true {
                if let index = self.content?.index(of: post) {
                    self.tableView.beginUpdates()
                    self.content?.remove(at: index)
                    self.tableView.deleteSections(IndexSet(integer: index), with: UITableViewRowAnimation.fade)
                    self.tableView.endUpdates()
                }
            }
        }
        
    }
    
    func contentFromList(_ list: NSOrderedSet?) -> [Content] {
        guard let subreddit = self.subreddit, !(self is PostDetailEmbeddedViewController) else {
            if let content: [Content] = list?.array as? [Content] {
                return content
            } else {
                return [Content]()
            }
            
        }
        guard let content: [Content] = list?.array as? [Content] else {
            return [Content]()
        }
        let shouldFilterSubreddits: Bool = subreddit.identifier == Subreddit.allIdentifier || subreddit.identifier == Subreddit.frontpageIdentifier
        let filteredContent: [Content] = content.filter { (content: Content) -> Bool in
            var postTitle: String?
            var subredditName: String?
            if let post: Post = content as? Post {
                postTitle = post.title
                subredditName = post.subreddit?.displayName

            } else if let comment: Comment = content as? Comment {
               postTitle = comment.post?.title
                subredditName = comment.post?.subreddit?.displayName
            }
            //containsString and length are faster on NSString than on swift string
            if let keywords = subreddit.filterKeywords, let title = postTitle?.lowercased(), title.count > 0 {
                for filterKeyword in keywords {
                    if title.contains(filterKeyword) {
                        //If it contains the keyword, we don't want to continue!
                        return false
                    }
                }
            }
            
            //containsString and length are faster on NSString than on swift string
            if shouldFilterSubreddits {
                if let filterSubreddits = subreddit.filterSubreddits, let subreddit = subredditName?.lowercased(), subreddit.count > 0 {
                    //If it contains the keyword, we don't want to continue!
                    return !filterSubreddits.contains(where: { (keyword) -> Bool in
                        return subreddit == keyword
                    })
                }
            }

            return true
        }
        return filteredContent
    }
    
    @objc func contentDidDelete(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            guard let post = notification.object as? Post, let index = self.content?.index(of: post) else {
                return
            }
            if self is PostDetailEmbeddedViewController {
                if let viewControllers = self.navigationController?.viewControllers, viewControllers.count > 1 {
                   _ = self.navigationController?.popViewController(animated: true)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.tableView.beginUpdates()
                self.content?.remove(at: index)
                self.tableView.deleteSections(IndexSet(integer: index), with: UITableViewRowAnimation.fade)
                self.tableView.endUpdates()
            }
        }
        
    }
    
    @objc func postSucessfullySubmitted(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let subreddit = notification.object as? Subreddit else {
                return
            }
            //Refresh the view if it's a content collection
            if let collection = self.query as? PostCollectionQuery, let content = self.content, collection.subreddit == subreddit && content.count != 0 {
                self.startCollectionControllerFetching(respectingExpirationDate: false, overwrite: true)
            } else if let userCollection = self.query as? UserContentCollectionQuery, let content = self.content, (userCollection.userContentType == .overview || userCollection.userContentType == .submitted || userCollection.userContentType == .upvoted) && content.count != 0 {
                self.startCollectionControllerFetching(respectingExpirationDate: false, overwrite: true)
            }
            
        }
    }
    
    @objc func postDidChangeSavedState(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            if let post = notification.object as? Post, post.isSaved.boolValue == true && self.content?.contains(post) == true {
                self.presentSuccessMessage(AWKLocalizedString("post-saved-succesfully"))
            } else if let comment = notification.object as? Comment, comment.isSaved.boolValue == true && self.content?.contains(comment) == true {
                self.presentSuccessMessage(AWKLocalizedString("comment-saved-succesfully"))
            }
        }
    }
    
    func showNSFWOverlayAtIndexPath(_ indexPath: IndexPath) -> Bool {
        guard self.visibleSubreddit?.shouldShowNSFWOverlay() ?? UserSettings[.showPrivacyOverlay] == true else {
            return false
        }
        let content = self.content?[indexPath.section]
        if let post = content as? Post {
            let nsfw = post.isContentNSFW.boolValue == true || (post.mediaObjects?.firstObject as? MediaObject)?.galleryItem.nsfw == true
            return nsfw
        } else {
            return false
        }
    }
    
    func showSpoilerOverlayAtIndexPath(_ indexPath: IndexPath) -> Bool {
        guard self.visibleSubreddit?.shouldShowSpoilerOverlay() ?? UserSettings[.showSpoilerOverlay] == true else {
            return false
        }
        let content = self.content?[indexPath.section]
        if let post = content as? Post {
            let spoiler = post.isContentSpoiler.boolValue == true
            return spoiler
        } else {
            return false
        }
    }
    
    var collection: ObjectCollection? {
        if let collectionID = self.collectionController.collectionID {
            do {
                return try AppDelegate.shared.managedObjectContext!.existingObject(with: collectionID) as? ObjectCollection
            } catch {
                return nil
            }
        }
        return nil
    }
    
    func cancelRequests() {
        self.cancelCollectionControllerFetching()
    }
    
    fileprivate func fetchMoreContent() {
        self.collectionController.startFetchingMore({ [weak self] (collectionID, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self?.content = self?.contentWithCollectionID(self?.collectionController.collectionID)
                
                if let error = error as NSError? {
                    if error.code == NSURLErrorNotConnectedToInternet && error.domain == NSURLErrorDomain {
                        self?.presentErrorMessage(AWKLocalizedString("error-loading-posts-internet"))
                    } else {
                        self?.presentErrorMessage(AWKLocalizedString("error-loading-posts"))
                    }
                }
            })
        })
        
        self.tableView.tableFooterView = nil
        self.loadingFooterView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.tableView.bounds.width, height: 100))
        self.tableView.tableFooterView = self.loadingFooterView
        self.loadingFooterView.startAnimating()
    }
    
    // MARK: - In-App Notifications
    
    @objc func refreshNotificationTimerFired(_ timer: Timer?) {
        if self.collectionController.isCollectionExpired == true && self.refreshNotification == nil && self.subreddit != nil {
            let refreshNotification = RefreshNotificationView()
            refreshNotification.addTarget(self, action: #selector(StreamViewController.refreshContent(_:)), for: .touchUpInside)
            if let subredditStream = self.parent as? SubredditStreamViewController, let displayView = subredditStream.toolbar {
                refreshNotification.displayView = displayView
            }
            self.refreshNotification = refreshNotification
            self.navigationController?.presentNotificationView(refreshNotification, style: .free, insets: refreshNotification.presentationEdgeInsets)
        }
    }
    
    func startRefreshNotificationTimer(_ fireDate: Date?) {
        if self.refreshNotificationTimer?.isValid == true {
            self.refreshNotificationTimer?.invalidate()
        }
        self.refreshNotificationTimer = nil
        
        if let fireDate = fireDate, fireDate.timeIntervalSinceNow > 0 {
            let newFireDate = fireDate.addingTimeInterval(20)
            let timer = Timer(fireAt: newFireDate, interval: 0, target: self, selector: #selector(StreamViewController.refreshNotificationTimerFired(_:)), userInfo: nil, repeats: false)
            timer.tolerance = 120
            self.refreshNotificationTimer = timer
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
        }
    }
    
    // MARK: Layout
    
    fileprivate var shouldShowSubredditInPosts: Bool {
        if !UserSettings[.showPostMetadataSubreddit] {
            return false
        }
        if let subreddit = self.visibleSubreddit {
            return subreddit is Multireddit || subreddit.identifier == Subreddit.frontpageIdentifier || subreddit.identifier == Subreddit.allIdentifier
        } else if let collection = self.collection as? PostCollection {
            return collection.subreddit is Multireddit || collection.subreddit?.identifier == Subreddit.frontpageIdentifier || collection.subreddit?.identifier == Subreddit.allIdentifier || self.subreddit == nil
        }
        return UserSettings[.showPostMetadataSubreddit]
    }
    
    fileprivate var shouldShowUsernameInPosts: Bool {
        if let userQuery = self.query as? UserContentCollectionQuery, userQuery.userContentType == UserContentType.submitted {
            return false
        }
        return UserSettings[.showPostMetadataUsername]
    }
    // MARK: - Actions
    
    @IBAction func unwindFromMediaOverviewToStream(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func refreshContent(_ sender: AnyObject?) {
        self.tableView.tableFooterView = nil
        self.refreshNotification?.dismiss()
        self.refreshNotification = nil
        if self.loadingState != .loading {
            self.startCollectionControllerFetching()
        }
    }
    
    fileprivate func presentGalleryFromIndexPath(_ indexPath: IndexPath, mediaAtIndex mediaIndex: Int, sourceView: UIImageView? = nil) {
        guard let content = self.content?[indexPath.section], let mediaObjects = content.mediaObjects?.array as? [MediaObject] else {
            return
        }
        self.gallerySourceIndexPath = indexPath
        let sourceView = sourceView ?? self.gallerySourceImageViewForItemAtIndex(mediaIndex)
        self.presentGallery(with: mediaObjects, initialMediaIndex: mediaIndex, post: content as? Post, sourceView: sourceView)
        if let post = content as? Post, UserSettings[.postMarking] {
            post.markVisited()
        }
        
    }
    
    fileprivate func showPostDetailViewForContent(_ content: Content?) {
        if let content = content, let viewController = self.detailViewControllerForContent(content) {
            if viewController is SFSafariViewController || viewController is UINavigationController {
                self.present(viewController, animated: true, completion: nil)
            } else {
               self.navigationController?.show(viewController, sender: self)
            }
            
        }
    }
    
    fileprivate func detailViewControllerForContent(_ content: Content) -> UIViewController? {
        if let post = content as? Post {
            if let mediaObjects = post.mediaObjects, mediaObjects.count > 1 {
                let storyboard = UIStoryboard(name: "MediaOverview", bundle: Bundle.main)
                let viewController = storyboard.instantiateViewController(withIdentifier: "PostMediaOverview")
                
                if let viewController = viewController as? PostMediaOverviewViewController {
                    viewController.post = post
                    viewController.visibleSubreddit = self.subreddit
                    return viewController
                }
            } else if let urlString = post.urlString, let URL = URL(string: urlString), let mediaObjects = post.mediaObjects, mediaObjects.count <= 0 && post.isSelfText.boolValue == false {
                let safariViewController = BeamSafariViewController(url: URL)
                return safariViewController
            } else {
                return PostDetailViewController(post: post, contextSubreddit: self.subreddit)
            }

        } else if let comment = content as? Comment {
            let viewController = UIStoryboard(name: "Comments", bundle: nil).instantiateViewController(withIdentifier: "comments") as! CommentsViewController
            
            let childQuery = CommentCollectionQuery()
            childQuery.post = comment.post
            if let parentComment = comment.parent as? Comment {
                    childQuery.parentComment = parentComment
            } else {
                childQuery.parentComment = comment
            }
            
            viewController.query = childQuery
            
            return viewController
        }
        return nil
    }
    
    // MARK: - Content
    
    fileprivate func content(forSection section: Int) -> Content? {
        guard let allContent = self.content, section < allContent.count else {
            return nil
        }
        if let content: Content = self.content?[section] {
            return content
        }
        return nil
    }
    
    // MARK: - MediaObjectsGalleryPresentation
    
    func bottomView(for gallery: AWKGalleryViewController, post: Post?) -> UIView? {
        let postToolbarXib = UINib(nibName: "GalleryPostBottomView", bundle: nil)
        let toolbar = postToolbarXib.instantiate(withOwner: nil, options: nil).first as? GalleryPostBottomView
        toolbar?.post = post
        toolbar?.shouldShowSubreddit = self.shouldShowSubredditInPosts
        toolbar?.toolbarView.delegate = self
        toolbar?.metadataView.delegate = self
        return toolbar
    }
    
}

// MARK: - UITableViewDataSource
extension StreamViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.content?.count ?? 0
    }
    
    fileprivate func postContainsMedia(_ post: Post?) -> Bool {
        return (post?.mediaObjects?.count ?? 0) > 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let content: Content = self.content(forSection: section) else {
            return 0
        }
        let cellIdentifiers = self.cellIdentifiersForContent(content)
        return cellIdentifiers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let content: Content = self.content(forSection: indexPath.section) else {
            let cell = tableView.dequeueReusableCell(withIdentifier: StreamCellTypeIdentifier.Title.rawValue, for: indexPath) as! PostCell
            self.configureCell(cell, atIndexPath: indexPath)
            return cell as! UITableViewCell
        }
        let cellIdentifiers = self.cellIdentifiersForContent(content)
        
        let post = content as? Post
        
        let cellType = cellIdentifiers[indexPath.row]
        
        let isDetailView = self is PostDetailEmbeddedViewController
        let thumbnailViewType = self.subreddit?.thumbnailViewType ?? UserSettings[.thumbnailsViewType]
        
        switch cellType {
        case .Metadata:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! PostMetaDataPartCell
            self.configureCell(cell, atIndexPath: indexPath)
            self.configureMetadataView(cell.metadataView, atIndexPath: indexPath)
            return cell
        case .Toolbar:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! PostToolbarPartCell
            configureCell(cell, atIndexPath: indexPath)
            cell.toolbarView.delegate = self
            cell.toolbarView.shouldShowSeperator = isDetailView || thumbnailViewType.showsToolbarSeperator
            return cell
        case .Image:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! PostImagePartCell
            cell.useCompactViewMode = self.useCompactViewMode
            cell.mediaObject = post?.mediaObjects?.firstObject as? MediaObject

            if self.showNSFWOverlayAtIndexPath(indexPath) {
                cell.spoilerView.buttonLabel.text = AWKLocalizedString("nsfw")
                cell.spoilerView.isHidden = false
            } else if self.showSpoilerOverlayAtIndexPath(indexPath) {
                cell.spoilerView.buttonLabel.text = AWKLocalizedString("spoiler")
                cell.spoilerView.isHidden = false
            } else {
                cell.spoilerView.isHidden = true
            }
            
            return cell
        case .Album:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! PostImageCollectionPartCell
            cell.mediaObjects = content.mediaObjects?.array as? [MediaObject]
            cell.post = content as? Post
            cell.visibleSubreddit = self.visibleSubreddit
            cell.delegate = self
            return cell
        case .SelfText:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! PostSelfTextPartCell
            let isSummary = !(self.collectionController.query is ObjectNamesQuery)
            cell.shouldShowSpoilerOverlay = self.showSpoilerOverlayAtIndexPath(indexPath)
            cell.shouldShowNSFWOverlay = self.showNSFWOverlayAtIndexPath(indexPath)
            cell.contentLabel.delegate = self
            cell.showsSummary = !isDetailView
            configureCell(cell, atIndexPath: indexPath)
            cell.selectionStyle = isSummary ? .default : .none
            return cell
        case .Comment:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! PostCommentPartCell
            cell.contentLabel.delegate = self
            cell.needsTopSpacing = !isDetailView && thumbnailViewType.needsCommentSpacing
            self.configureCell(cell, atIndexPath: indexPath)
            cell.selectionStyle = isDetailView ?  .none : .default
            return cell
        case .TitleWithThumbnail:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! PostTitlePartCell
            cell.shouldShowSpoilerOverlay = self.showSpoilerOverlayAtIndexPath(indexPath)
            cell.shouldShowNSFWOverlay = self.showNSFWOverlayAtIndexPath(indexPath)
            cell.delegate = self
            cell.showThumbnail = thumbnailViewType != ThumbnailsViewType.none
            self.configureCell(cell, atIndexPath: indexPath)
            if let metadataView = cell.metadataView {
                self.configureMetadataView(metadataView, atIndexPath: indexPath)
            }
            return cell
        case .Link, .Video:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! PostURLPartCell
            cell.shouldShowSpoilerOverlay = self.showSpoilerOverlayAtIndexPath(indexPath)
            cell.shouldShowNSFWOverlay = self.showNSFWOverlayAtIndexPath(indexPath)
            self.configureCell(cell, atIndexPath: indexPath)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.rawValue, for: indexPath) as! PostCell
            self.configureCell(cell, atIndexPath: indexPath)
            return cell as! UITableViewCell
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let imagePartCell = cell as? PostImagePartCell {
            imagePartCell.prepareGIFPlayback()
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let imagePartCell = cell as? PostImagePartCell {
            imagePartCell.gifPlayerView.stop()
        }
    }
    
    fileprivate func cellIdentifiersForContent(_ content: Content?) -> [StreamCellTypeIdentifier] {
        var identifiers: [StreamCellTypeIdentifier] = [.Title, .Metadata, .Link, .Toolbar]
        
        let isDetailView = self is PostDetailEmbeddedViewController
        let thumbnailType = self.subreddit?.thumbnailViewType ?? UserSettings[.thumbnailsViewType]
        let showTitleWithThumbnail = (thumbnailType == ThumbnailsViewType.none || thumbnailType == ThumbnailsViewType.small) && isDetailView == false
        
        var shouldShowNSFWOverlay = self.visibleSubreddit?.shouldShowNSFWOverlay() ?? true
        var shouldShowSpoilerOverlay = self.visibleSubreddit?.shouldShowSpoilerOverlay() ?? true
        if isDetailView {
            //Detail view never shows the NSFW overlay
            shouldShowNSFWOverlay = false
            shouldShowSpoilerOverlay = false
        }
        
        if showTitleWithThumbnail && !(content is Comment) && isDetailView == false {
            identifiers = [.TitleWithThumbnail, .Toolbar]
        } else {
            
            if let post = content as? Post {
                if post.isSelfText.boolValue == true {
                    //If the post contains no text, we don't include the text cell. Except for when the post is NSFW or contains spoilers and the overlay is enabled
                    if NSString(string: post.content ?? "").length == 0 && (!post.isContentNSFW.boolValue || shouldShowNSFWOverlay == false) && (!post.isContentSpoiler.boolValue || shouldShowSpoilerOverlay == false) {
                        identifiers = [.Title, .Metadata, .Toolbar]
                    } else {
                        if isDetailView {
                            identifiers = [.Title, .SelfText, .Metadata, .Toolbar]
                        } else {
                            identifiers = [.Title, .SelfText, .Metadata, .Toolbar]
                        }
                        
                    }
                } else if let mediaObjects = post.mediaObjects, mediaObjects.count > 1 {
                    identifiers = [.Title, .Metadata, .Album, .Toolbar]
                } else if post.mediaObjects?.count == 1 {
                    identifiers = [.Title, .Metadata, .Image, .Toolbar]
                } else if let urlString = post.urlString, let url = URL(string: urlString), url.estimatedURLType == URLType.video {
                    identifiers = [.Title, .Metadata, .Video, .Toolbar]
                }
            } else if content is Comment {
                if showTitleWithThumbnail {
                identifiers = [.TitleWithThumbnail, .Comment]
                } else {
                    identifiers = [.Title, .Metadata, .Comment]
                }
                
            }
        }

        if !UserSettings[.showPostMetadata] && !isDetailView {
            if let index = identifiers.index(of: .Metadata) {
                identifiers.remove(at: index)
            }
        }
        return identifiers
    }
    
    fileprivate func configureMetadataView(_ metadataView: PostMetadataView, atIndexPath indexPath: IndexPath) {
        let thumbnailViewType = self.subreddit?.thumbnailViewType ?? UserSettings[.thumbnailsViewType]
        let isDetailView = self is PostDetailEmbeddedViewController
        metadataView.delegate = self
        metadataView.shouldShowSubreddit = self.shouldShowSubredditInPosts
        metadataView.shouldShowUsername = self.shouldShowUsernameInPosts
        metadataView.shouldShowGilded = UserSettings[.showPostMetadataGilded]
        metadataView.shouldShowDomain = UserSettings[.showPostMetadataDomain] && !isDetailView && thumbnailViewType.showsDomain
        metadataView.shouldShowLocked = UserSettings[.showPostMetadataLocked]
        metadataView.shouldShowStickied = UserSettings[.showPostMetadataStickied]
        metadataView.shouldShowDate = UserSettings[.showPostMetadataDate] && !(self.content?[indexPath.section] is Comment)
    }
    
    fileprivate func configureCell(_ cell: PostCell, atIndexPath indexPath: IndexPath) {
        if let object = self.content(forSection: indexPath.section) {
            cell.content = object
            cell.onDetailView = (self is PostDetailEmbeddedViewController)
        }
        if let commentCell = cell as? PostCommentPartCell, let object = self.content?[indexPath.section] {
            commentCell.comment = object as? Comment
        }
    }
    
    // MARK: - Autoplaying Gifs
    
    fileprivate func pauseAllPlayingGifs() {
        let imageCells: [PostImagePartCell] = self.tableView.visibleCells.filter { (cell) -> Bool in
            return cell is PostImagePartCell
            }.map { (cell) -> PostImagePartCell in
                cell as! PostImagePartCell
        }
        for cell in imageCells {
            cell.gifPlayerView.pause()
        }
    }
    
    fileprivate func updateGifPlayingState() {
        guard GIFPlayerView.canAutoplayGifs else {
            return
        }
        
        /**
         While scrolling we want to pause gifs that are not completly visible to the user and play them when they do become visible.
         We calculate a visible rect using some insets, then check if the rect of a visible cell is in the visible rect.
         We do this using intersects instead of constains. In case the visble rect height/width is negative the cell rect will still intersect, while the rect doesn't contain the cell rect.
        */
        
        let visibleRect = UIEdgeInsetsInsetRect(self.tableView.frame, StreamViewController.visibleContentInset)
        
        for cell in self.tableView.visibleCells {
            guard let indexPath = self.tableView.indexPath(for: cell), let imagePartCell = cell as? PostImagePartCell else {
                continue
            }
            let rectOfCell = self.tableView.rectForRow(at: indexPath)
            let rectOfCellInSuperview = self.tableView.convert(rectOfCell, to: self.tableView.superview)
            if visibleRect.intersects(rectOfCellInSuperview) && imagePartCell.gifPlayerView.isPlaying == false {
                imagePartCell.gifPlayerView.play()
            } else if visibleRect.intersects(rectOfCellInSuperview) == false && imagePartCell.gifPlayerView.isPlaying == true && !(self is PostDetailEmbeddedViewController) {
                imagePartCell.gifPlayerView.pause()
            }
        }
    }
    
}

// MARK: - UITableViewDelegate

extension StreamViewController {
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.hidingButtonBarDelegate?.buttonBarScrollViewDidScroll(scrollView)
        
        self.updateGifPlayingState()
        
        //Determine if the user is in the "load more" scroll region
        if scrollView.contentOffset.y > scrollView.contentSize.height - (UIScreen.main.bounds.height * 1.5) && scrollView.contentSize.height > scrollView.frame.height {
                
            guard !(self.hasEnteredLoadMoreState && self.collectionController.error != nil) else {
                AWKDebugLog("The user has already tried loading more content but has hit an error. the user has to scroll up again to fix this")
                return
            }
            
            guard self.collectionController.moreContentAvailable else {
                return
            }
            
            self.hasEnteredLoadMoreState = true
                
        } else {
            self.hasEnteredLoadMoreState = false
        }
    }
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        self.hidingButtonBarDelegate?.buttonBarScrollViewDidScrollToTop(scrollView)
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let isDetailView = self is PostDetailEmbeddedViewController
        if let cell = cell as? PostImagePartCell {
            let isNSFWOrSpoiler = self.showNSFWOverlayAtIndexPath(indexPath) || self.showSpoilerOverlayAtIndexPath(indexPath)
            if (isNSFWOrSpoiler && (cell.spoilerView.opened || cell.spoilerView.isHidden)) || !isNSFWOrSpoiler {
                presentGalleryFromIndexPath(indexPath, mediaAtIndex: 0)
            }
        } else if cell is PostSelfTextPartCell && !isDetailView {
            self.showPostDetailViewForContent( self.content?[indexPath.section])
        } else if cell is PostCommentPartCell && !isDetailView {
            self.showPostDetailViewForContent( self.content?[indexPath.section])
        } else if let titlePartCell = cell as? PostTitlePartCell, let post = titlePartCell.post, !isDetailView {
            self.navigationController?.show(PostDetailViewController(post: post, contextSubreddit: self.subreddit), sender: true)
        } else if let metaDataPartCell = cell as? PostMetaDataPartCell, let post = metaDataPartCell.post, !isDetailView {
            self.navigationController?.show(PostDetailViewController(post: post, contextSubreddit: self.subreddit), sender: true)
        } else if let toolbarPartCell = cell as? PostToolbarPartCell, let post = toolbarPartCell.post, !isDetailView {
            self.navigationController?.show(PostDetailViewController(post: post, contextSubreddit: self.subreddit), sender: true)
        } else if let cell = cell as? PostURLPartCell, let urlString = cell.post?.urlString, let url = URL(string: urlString) {
            if ExternalLinkOpenOption.shouldShowPrivateBrowsingWarning() {
                ExternalLinkOpenOption.showPrivateBrowsingWarning(url, on: self)
            } else {
                if let viewController = AppDelegate.shared.openExternalURLWithCurrentBrowser(url) {
                    self.present(viewController, animated: true, completion: nil)
                }
            }
            
        }
        
        if let postCell = cell as? PostCell {
            if UserSettings[.postMarking] {
                postCell.post?.markVisited()
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (self.subreddit?.thumbnailViewType ?? UserSettings[.thumbnailsViewType]).headerSpacingHeight(atIndex: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (self.subreddit?.thumbnailViewType ?? UserSettings[.thumbnailsViewType]).footerSpacingHeight(atIndex: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let content = self.content(forSection: indexPath.section) {
            let cellIndentifiers = self.cellIdentifiersForContent(content)
            switch cellIndentifiers[indexPath.row] {
            case StreamCellTypeIdentifier.Metadata:
                return 32
            case StreamCellTypeIdentifier.Toolbar:
                return 44
            case StreamCellTypeIdentifier.Link:
                return PostURLPartCell.heightForLink(isVideo: false, forWidth: tableView.frame.width)
            case StreamCellTypeIdentifier.Video:
                return PostURLPartCell.heightForLink(isVideo: true, forWidth: tableView.frame.width)
            case StreamCellTypeIdentifier.Image:
                return PostImagePartCell.heightForMediaObject(content.mediaObjects?.firstObject as? MediaObject, useCompactViewMode: self.useCompactViewMode, forWidth: tableView.frame.width)
            case StreamCellTypeIdentifier.Album:
                return StreamAlbumView.sizeWithNumberOfMediaObjects(content.mediaObjects!.count, maxWidth: tableView.bounds.width).height
            default:
                
                return UITableViewAutomaticDimension
            }
        }
        return 1.0
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let content = self.content(forSection: indexPath.section) {
            let cellIndentifiers = self.cellIdentifiersForContent(content)
            switch cellIndentifiers[indexPath.row] {
            case StreamCellTypeIdentifier.Metadata:
                return 32
            case StreamCellTypeIdentifier.Toolbar:
                return 44
            case StreamCellTypeIdentifier.Link:
                return PostURLPartCell.heightForLink(isVideo: false, forWidth: tableView.frame.width)
            case StreamCellTypeIdentifier.Video:
                return PostURLPartCell.heightForLink(isVideo: true, forWidth: tableView.frame.width)
            case StreamCellTypeIdentifier.Image:
                return PostImagePartCell.heightForMediaObject(content.mediaObjects?.firstObject as? MediaObject, useCompactViewMode: self.useCompactViewMode, forWidth: tableView.frame.width)
            case StreamCellTypeIdentifier.Album:
                return StreamAlbumView.sizeWithNumberOfMediaObjects(content.mediaObjects!.count, maxWidth: tableView.bounds.width).height
            default:
                return tableView.estimatedRowHeight
            }
        }
        return 1.0
    }
    
}

// MARK: - PostImageCollectionPartCellDelegate
extension StreamViewController: PostImageCollectionPartCellDelegate {
    
    func postImageCollectionPartCell(_ cell: PostImageCollectionPartCell, didTapMediaObjectAtIndex mediaIndex: Int) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            self.presentGalleryFromIndexPath(indexPath, mediaAtIndex: mediaIndex)
        }
        
    }
    
    func postImageCollectionPartCell(_ cell: PostImageCollectionPartCell, didTapMoreButtonAtIndex mediaIndex: Int) {
        
        if let indexPath = self.tableView.indexPath(for: cell) {
            let storyboard = UIStoryboard(name: "MediaOverview", bundle: Bundle.main)
            let viewController = storyboard.instantiateViewController(withIdentifier: "PostMediaOverview")
            
            if let viewController = viewController as? PostMediaOverviewViewController {
                viewController.post = self.content?[indexPath.section] as? Post
                viewController.visibleSubreddit = self.subreddit
                self.navigationController?.pushViewController(viewController, animated: true)
                if UserSettings[.postMarking] {
                    cell.post?.markVisited()
                }
            }
        }
        
    }
    
}

extension StreamViewController: PostToolbarViewDelegate {

    func visibleSubredditForToolbarView(_ toolbarView: PostToolbarView) -> Subreddit? {
        return self.visibleSubreddit
    }
    
}

// MARK: - TTTAttributedLabelDelegate
extension StreamViewController: TTTAttributedLabelDelegate {
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if ExternalLinkOpenOption.shouldShowPrivateBrowsingWarning() {
            ExternalLinkOpenOption.showPrivateBrowsingWarning(url, on: self)
        } else {
            if let viewController = AppDelegate.shared.openExternalURLWithCurrentBrowser(url) {
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
}

//MARL: - AWKGalleryDataSource

extension StreamViewController: AWKGalleryDataSource {
    
    // MARK: - AWKGalleryDataSource
    
    func numberOfItems(inGallery galleryViewController: AWKGalleryViewController) -> Int {
        guard let mediaObjects = self.galleryMediaObjects else {
            return 0
        }
        return mediaObjects.count
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, itemAt index: UInt) -> AWKGalleryItem {
        if let mediaObject = self.galleryMediaObjects?[Int(index)] {
            return mediaObject.galleryItem
        } else {
            fatalError()
        }
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, indexOf item: AWKGalleryItem) -> Int {
        return (self.galleryMediaObjects?.index(where: { (mediaObject: MediaObject) -> Bool in
            return mediaObject.contentURLString == item.contentURL?.absoluteString
        })) ?? 0
    }
    
}

// MARK: - AWKGalleryDelegate

extension StreamViewController: AWKGalleryDelegate {
    
    func gallery(_ galleryViewController: AWKGalleryViewController, presentationAnimationSourceViewFor item: AWKGalleryItem) -> UIView? {
        let index = self.gallery(galleryViewController, indexOf: item)
        return self.gallerySourceImageViewForItemAtIndex(index)
    }
    
    func gallerySourceImageViewForItemAtIndex(_ index: Int) -> UIImageView? {
        if let indexPath = self.gallerySourceIndexPath, let cell = self.tableView.cellForRow(at: indexPath) as? MediaImageLoader {
            return cell.mediaImageView
        } else if let indexPath = self.gallerySourceIndexPath, let cell = self.tableView.cellForRow(at: indexPath) as? PostImageCollectionPartCell {
            return cell.imageViewAtIndex(index)
        } else if let indexPath = self.gallerySourceIndexPath, let cell = self.tableView.cellForRow(at: indexPath) as? PostTitlePartCell, index == 0 {
            return cell.thumbnailView?.mediaImageView
        }
        return nil
    }
    
    func gifPlayerViewForItemAtIndex(_ index: Int) -> GIFPlayerView? {
        if let indexPath = self.gallerySourceIndexPath, let cell = self.tableView.cellForRow(at: indexPath) as? PostImagePartCell {
            return cell.gifPlayerView
        }
        return nil
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, shouldBeDismissedAnimated animated: Bool) {
        if let currentItem = galleryViewController.currentItem {
            let index = self.gallery(galleryViewController, indexOf: currentItem)
            self.dismissGalleryViewController(galleryViewController, sourceView: self.gallerySourceImageViewForItemAtIndex(index))
        } else {
            self.dismissGalleryViewController(galleryViewController, sourceView: nil)
        }
    }
    
    func gallery(_ galleryViewController: AWKGalleryViewController, didScrollFrom item: AWKGalleryItem) {
        // The current cell always needs to be hidden due to a possible dismissal animation or an alpha background color on the gallery. Unhide the old gallery item.
        
        let fromIndex = self.gallery(galleryViewController, indexOf: item)
        self.gallerySourceImageViewForItemAtIndex(fromIndex)?.isHidden = false
        
        if let currentItem = galleryViewController.currentItem {
            let toIndex = self.gallery(galleryViewController, indexOf: currentItem)
            self.gallerySourceImageViewForItemAtIndex(toIndex)?.isHidden = true
        }
        
    }
    
}

// MARK: - PostTitlePartCellDelegate

extension StreamViewController: PostTitlePartCellDelegate {

    func titlePartCell(_ cell: PostTitlePartCell, didTapThumbnail thumbnailImageView: UIImageView, onPost post: Post) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            if let URLString = post.urlString, let url = URL(string: URLString), url.estimatedURLType == URLType.video {
                if ExternalLinkOpenOption.shouldShowPrivateBrowsingWarning() {
                    ExternalLinkOpenOption.showPrivateBrowsingWarning(url, on: self)
                } else if let viewController = AppDelegate.shared.openExternalURLWithCurrentBrowser(url) {
                    self.present(viewController, animated: true, completion: nil)
                }
            } else {
                self.presentGalleryFromIndexPath(indexPath, mediaAtIndex: 0, sourceView: thumbnailImageView)
            }
        }
    }
    
}

// MARK: - CollectionControllerDelegate
extension StreamViewController: CollectionControllerDelegate {

    func collectionController(_ controller: CollectionController, collectionDidUpdateWithID objectID: NSManagedObjectID?) {
        if let refreshTimer = self.refreshNotificationTimer, let collection = self.collection, let expirationDate = collection.expirationDate, refreshTimer.fireDate != expirationDate {
            self.startRefreshNotificationTimer(expirationDate)
        } else if self.collection?.expirationDate == nil {
            self.startRefreshNotificationTimer(nil)
        }
    }
}

// MARK: - UIViewControllerPreviewingDelegate
@available(iOS 9, *)
extension StreamViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location),
            let cell = self.tableView.cellForRow(at: indexPath) else {
                return nil
        }
        if self is PostDetailEmbeddedViewController {
            //Note on the URL scheme check: some URLs in comments might be a custom URL scheme. However SFSafariViewController only supports http/https links
            let contentViewPoint = self.tableView.convert(location, to: cell.contentView)
            if let selfTextCell = cell as? PostSelfTextPartCell, let link = selfTextCell.link(at: contentViewPoint), link.scheme?.contains("http") == true {
                return BeamSafariViewController(url: link)
            } else if let commentCell = cell as? CommentCell, let link = commentCell.link(at: contentViewPoint), link.scheme?.contains("http") == true {
                commentCell.cancelLongPress()
                return BeamSafariViewController(url: link)
            } else if let commentCell = cell as? CommentCell, commentCell.commentLinkPreview.frame.contains(contentViewPoint) && !commentCell.commentLinkPreview.isHidden {
                commentCell.cancelLongPress()
                previewingContext.sourceRect = self.tableView.convert(commentCell.commentLinkPreview.frame, from: cell.contentView)
                
                if let mediaObjects = commentCell.comment?.mediaObjects?.array as? [MediaObject], let mediaObject = mediaObjects.first {
                    self.galleryMediaObjects = mediaObjects
                    let galleryViewController = self.galleryViewController(for: mediaObject, post: nil)
                    galleryViewController.shouldAutomaticallyDisplaySecondaryViews = false
                    galleryViewController.preferredContentSize = mediaObject.viewControllerPreviewingSize()
                    return galleryViewController
                } else if let link = commentCell.commentLinkPreview.link, link.scheme?.contains("http") == true {
                    return BeamSafariViewController(url: link)
                }
                
            }
            return nil
        } else {
            if let postCell = cell as? PostCell, UserSettings[.postMarking] {
                postCell.post?.markVisited()
            } else if let mediaCell = cell as? MediaImageLoader, UserSettings[.postMarking] {
                (mediaCell.mediaObject?.content as? Post)?.markVisited()
            }
            
            var viewController: UIViewController?
            var sourceRect: CGRect?
            if let URLPartCell = cell as? PostURLPartCell, let URLString = URLPartCell.post?.urlString, let URL = URL(string: URLString)?.mobileURL {
                sourceRect = self.tableView.convert(URLPartCell.linkContainerViewFrame, from: cell.contentView)
                viewController = BeamSafariViewController(url: URL)
            } else if let selfTextPartCell = cell as? PostSelfTextPartCell, let post = selfTextPartCell.post {
                
                viewController = self.detailViewControllerForContent(post)
            } else if let commentPartCell = cell as? PostCommentPartCell, let comment = commentPartCell.comment {
                viewController = self.detailViewControllerForContent(comment)
            } else if let titlePartCell = cell as? PostTitlePartCell, let post = titlePartCell.post {
                let convertedPoint = self.tableView.convert(location, to: titlePartCell.contentView)
                if let mediaItem = post.mediaObjects?.firstObject as? MediaObject, titlePartCell.pointInsideThumbnail(convertedPoint) == true {
                    let galleryViewController = self.galleryViewController(for: mediaItem, post: post)
                    galleryViewController.shouldAutomaticallyDisplaySecondaryViews = false
                    viewController = galleryViewController
                    viewController?.preferredContentSize = mediaItem.viewControllerPreviewingSize()
                    sourceRect = self.tableView.convert(titlePartCell.thumbnailView!.frame, from: titlePartCell.contentView)
                } else {
                    viewController = PostDetailViewController(post: post, contextSubreddit: self.subreddit)
                }
            } else if let toolbarPartCell = cell as? PostToolbarPartCell, let post = toolbarPartCell.post {
                viewController = PostDetailViewController(post: post, contextSubreddit: self.subreddit)
            } else if cell is PostImagePartCell || cell is PostImageCollectionPartCell {
                self.gallerySourceIndexPath = indexPath
                
                let post = self.content?[indexPath.section]
                self.galleryMediaObjects = post?.mediaObjects?.array as? [MediaObject]
                
                var mediaItem = self.galleryMediaObjects?[0]
                if let imageCollectionPartCell = cell as? PostImageCollectionPartCell,
                    let cellMediaItem = imageCollectionPartCell.mediaItemAtLocation(cell.contentView.convert(location, from: self.tableView)),
                    let albumItemView = imageCollectionPartCell.albumItemViewAtLocation(cell.contentView.convert(location, from: self.tableView)) {
                        
                        sourceRect = self.tableView.convert(albumItemView.frame, from: cell.contentView)
                        mediaItem = cellMediaItem
                }
                
                if let post = post as? Post, let mediaItem = mediaItem {
                    let galleryViewController = self.galleryViewController(for: mediaItem, post: post)
                    galleryViewController.shouldAutomaticallyDisplaySecondaryViews = false
                    viewController = galleryViewController
                    viewController?.preferredContentSize = mediaItem.viewControllerPreviewingSize()
                }
            }

            //Set the frame to animate the peek from
            previewingContext.sourceRect = sourceRect ?? cell.frame
            
            //Pass the view controller to display
            return viewController
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if viewControllerToCommit is SFSafariViewController || viewControllerToCommit is UINavigationController {
            self.present(viewControllerToCommit, animated: true, completion: nil)
        } else if let galleryViewController = viewControllerToCommit as? AWKGalleryViewController {
            galleryViewController.shouldAutomaticallyDisplaySecondaryViews = true
            self.presentGalleryViewController(galleryViewController, sourceView: nil)
        } else {
            self.navigationController?.show(viewControllerToCommit, sender: previewingContext)
        }
    }
}
