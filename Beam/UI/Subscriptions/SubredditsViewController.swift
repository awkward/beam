//
//  SubredditsViewController.swift
//  beam
//
//  Created by Robin Speijer on 22-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData
import Trekker

final class SubredditsViewControllerSection: NSObject {
    var sectionName: String
    var subreddits: [Subreddit]
    
    init(_ sectionName: String, _ subreddits: [Subreddit]) {
        self.sectionName = sectionName
        self.subreddits = subreddits
        super.init()
    }
    
}

final class SubredditsViewController: BeamTableViewController, BeamViewControllerLoading {
    
    // MARK: - Properties
    
    fileprivate var editContext: NSManagedObjectContext?
    
    weak var hidingButtonBarDelegate: HidingButtonBarDelegate?
    
    fileprivate var bannerView: TableViewHeaderBannerView? {
        didSet {
            if self.tableView.tableHeaderView != nil {
                //Setting the header to nil while it's already nil causes layouting to be invoked on the tableView. This causes stuttering in animations
                self.tableView.tableHeaderView = nil
            }
            if self.bannerView != nil {
                self.bannerView!.sizeToFit()
                var layoutMargings = self.bannerView!.layoutMargins
                //Add the inset of the section titles scrubber
                layoutMargings.right += 20
                self.bannerView?.layoutMargins = layoutMargings
                self.tableView.tableHeaderView = self.bannerView
            }
        }
    }
    // This is used to work around a bug in iOS 9, see viewDidlayoutSubviews below
    fileprivate var previousViewSize: CGSize?
    
    // MARK: - BeamViewControllerLoading
    
    typealias CollectionItem = SubredditsViewControllerSection
    
    var collectionController = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
    
    var content: [SubredditsViewControllerSection]? {
        didSet {
            if !self.isEditing {
                self.tableView.reloadData()
            }
            AppDelegate.shared.updateFavoriteSubredditShortcuts()
            AppDelegate.shared.updateSearchableSubreddits()
        }
    }
    var loadingState: BeamViewControllerLoadingState = .empty
    var emptyView: BeamEmptyView? {
        didSet {
            self.tableView.backgroundView = self.emptyView
            self.tableView.separatorStyle = self.emptyView == nil ? .singleLine : .none
            self.tableView.reloadData()
            self.emptyView?.layoutMargins = self.tableView.contentInset
            
            if self.emptyView == nil {
                self.showBannerIfAvailable()
            }
        }
    }
    var defaultEmptyViewType: BeamEmptyViewType = BeamEmptyViewType.MultiredditNoSubreddits
    
    func collectionHasSubreddits(collectionID: NSManagedObjectID?) -> Bool {
        let content = self.contentWithCollectionID(collectionID)
        if content.count == 1 {
            if let section = content.first {
                return section.subreddits.count > 2
            }
            return false
        }
        return content.count > 0
    }
    
    func contentFromList(_ list: NSOrderedSet?) -> [SubredditsViewControllerSection] {
        
        if let subredditList: NSMutableOrderedSet = list?.mutableCopy() as? NSMutableOrderedSet {
            
            subredditList.sort(using: [NSSortDescriptor(key: "sectionName", ascending: true), NSSortDescriptor(key: "order", ascending: true), NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "identifier", ascending: true)])
            var content: [SubredditsViewControllerSection] = [SubredditsViewControllerSection]()
            
            let bookmarkedSubreddits: [Subreddit] = self.bookmarkedSubredditsFromList(list)
            
            // Reset positions to make it always work
            if bookmarkedSubreddits.filter({ (subreddit) -> Bool in
                return subreddit.isPrepopulated == true
            }).count > 0 {
                //Only reset the position if we have pre-populated subreddits, otherwise we are going to fuck up the sorting
                var index: Int = 0
                for bookmark: Subreddit in bookmarkedSubreddits {
                    bookmark.order = NSNumber(value: index)
                    index += 1
                }
            }
            
            content.append(SubredditsViewControllerSection("★", bookmarkedSubreddits))
            subredditList.removeObjects(in: bookmarkedSubreddits)
            
            var currentSection: SubredditsViewControllerSection? = nil
            for enumerationObject in subredditList {
                if let subreddit: Subreddit = enumerationObject as? Subreddit, let name: String = subreddit.sectionName {
                    
                    let subreddits: [Subreddit] = [subreddit]
                    let uppercaseName: String = name.uppercased(with: Locale.current)
                    
                    if currentSection == nil {
                        currentSection = SubredditsViewControllerSection(uppercaseName, subreddits)
                    } else if currentSection!.sectionName == uppercaseName {
                        currentSection!.subreddits.append(subreddit)
                    } else {
                        content.append(currentSection!)
                        currentSection = SubredditsViewControllerSection(uppercaseName, subreddits)
                    }
                }
            }
            if let lastSection: SubredditsViewControllerSection = currentSection {
                content.append(lastSection)
                currentSection = nil
            }
            
            return content
        } else {
            return [SubredditsViewControllerSection]()
        }
    }
    
    fileprivate func bookmarkedSubredditsFromList(_ list: NSOrderedSet?) -> [Subreddit] {
        
        // Use prepopulated subreddits from list to prevent duplicates
        let subreddits: [Subreddit]? = list?.array as? [Subreddit]
        let filteredSubreddits: [Subreddit]? = subreddits?.filter({
            let subreddit: Subreddit = $0
            return subreddit.isPrepopulated == true
        })
        let prepopulated: [Subreddit]!
        if let filteredSubreddits: [Subreddit] = filteredSubreddits {
            prepopulated = filteredSubreddits
        } else {
            prepopulated = [Subreddit]()
        }
        
        // Use real subreddits from the database
        do {
            let fetchRequest: NSFetchRequest = NSFetchRequest<Subreddit>(entityName: Subreddit.entityName())
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true), NSSortDescriptor(key: "displayName", ascending: true, selector:
                #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "identifier", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "isBookmarked == YES")
            let fetchedSubreddits = try AppDelegate.shared.managedObjectContext.fetch(fetchRequest)
            let nonPrePopulated: [Subreddit]? = fetchedSubreddits.filter({
                let subreddit: Subreddit = $0
                return subreddit.isPrepopulated == false
            })
            
            // Merge and sort based on order
            
            var combinedSubreddits: [Subreddit] = prepopulated
            
            if let nonPrePopulated: [Subreddit] = nonPrePopulated {
                combinedSubreddits.append(contentsOf: nonPrePopulated)
            }
            combinedSubreddits.sort(by: {
                let subreddit1: Subreddit = $0
                let subreddit2: Subreddit = $1
                return subreddit1.order.intValue < subreddit2.order.intValue
            })
            
            return combinedSubreddits
        } catch {
            return prepopulated
        }
        
    }
    
    func shouldShowLoadingView() -> Bool {
        return self.collectionHasSubreddits(collectionID: self.collectionController.collectionID) == false
    }
    
    func shouldFetchCollection(respectingExpirationDate respectExpirationDate: Bool) -> Bool {
        if self.collectionHasSubreddits(collectionID: self.collectionController.collectionID) == false {
            return true
        }
        return (!respectExpirationDate || self.collectionController.isCollectionExpired != false)
    }
    
    fileprivate func indexPathForSubreddit(_ subreddit: Subreddit) -> IndexPath? {
        guard let content = self.content else {
            return nil
        }
        for (sectionIdx, section) in content.enumerated() {
            if let rowIndex = section.subreddits.index(where: { (object) -> Bool in
                return object == subreddit
            }) {
                return IndexPath(row: rowIndex, section: sectionIdx)
            }
        }
        return nil
    }
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
        
        self.setupViewController()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.setupViewController()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.setupViewController()
    }
    
    private func setupViewController() {
        let query = SubredditsCollectionQuery()
        query.userIdentifier = AppDelegate.shared.authenticationController.activeUserIdentifier
        
        self.collectionController.query = query
        
        self.collectionController.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditsViewController.authenticatedUserDidChange(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditsViewController.expiredContentDeleted(_:)), name: .DataControllerExpiredContentDeletedFromContext, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditsViewController.subscriptionsDidChange(_:)), name: .SubredditSubscriptionDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditsViewController.cherryFeaturesDidChange(_:)), name: .CherryFeaturesDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditsViewController.bookmarksDidChange(notification:)), name: .SubredditBookmarkDidChange, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(SubredditTableViewCell.self)
        
        self.tableView.register(BeamPlainTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
        self.navigationItem.leftBarButtonItem = self.editButtonItem
    
        self.updateTitle()
        
        self.registerForPreviewing(with: self, sourceView: self.tableView)
        
        //Add a refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshContent(sender:)), for: .valueChanged)
        self.refreshControl = refreshControl

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        self.startCollectionControllerFetching(respectingExpirationDate: (self.collectionController.status != .idle))
        
        if self.bannerView == nil {
            self.showBannerIfAvailable()
        }

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func refreshContent(sender: UIRefreshControl) {
        self.startCollectionControllerFetching(respectingExpirationDate: false)
    }
    
    fileprivate func updateTitle() {
        if AppDelegate.shared.authenticationController.isAuthenticated {
            self.title = AWKLocalizedString("subscriptions-title")
        } else {
            self.title = AWKLocalizedString("subreddits-title")
        }
    }
    
    // MARK: - Banner
    
    fileprivate func showBannerIfAvailable() {
        guard self.tableView.numberOfSections > 0 && self.tableView.tableHeaderView == nil else {
            //If the tableview doesn't have any sections, don't show the table header. Also not when it already has an header
            return
        }
        
        if let notification = AppDelegate.shared.cherryController.features?.bannerNotifications?.first(where: { $0.shouldDisplay == true }) {
            self.bannerView = TableViewHeaderBannerView.bannerView(notification, tapHandler: { (notification) in
               AppDelegate.shared.userNotificationsHandler.handleNotificationContent(notification.userNotificationContent)
                self.removeBanner()
                }, closeHandler: { (_) in
                    self.removeBanner()
            })
        } else {
            self.bannerView = nil
        }
        
    }
    
    fileprivate func removeBanner() {
        self.bannerView = nil
    }
    
    // MARK: - Actions
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            self.editContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
            self.editContext?.parent = AppDelegate.shared.managedObjectContext
        } else {
            let saveOperations = DataController.shared.persistentSaveOperations(AppDelegate.shared.managedObjectContext)
            DataController.shared .executeOperations(saveOperations, handler: { (error) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if let error = error {
                        AWKDebugLog("Could not save favorite changes: \(error)")
                    } else {
                        AppDelegate.shared.updateFavoriteSubredditShortcuts()
                    }
                })
                
            })
            
            self.editContext = nil
        }
        
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func authenticatedUserDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] () -> Void in
            
            self?.updateTitle()
            
            if self?.collectionController.status == .fetching {
                self?.collectionController.cancelFetching()
            }
            
            let query = SubredditsCollectionQuery()
            query.userIdentifier = AppDelegate.shared.authenticationController.activeUserIdentifier
            self?.collectionController.query = query
            
            self?.startCollectionControllerFetching(respectingExpirationDate: false)
            
            self?.showBannerIfAvailable()
        }
    }
    
    @objc fileprivate func expiredContentDeleted(_ notification: Notification) {
        if let managedObjectContext = notification.object as? NSManagedObjectContext, managedObjectContext.deletedObjects.contains( where: { $0 is Subreddit }) {
            DispatchQueue.main.async {
                self.startCollectionControllerFetching(respectingExpirationDate: true)
            }
        }
    }
    
    @objc fileprivate func subscriptionsDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.collectionController.cancelFetching()
            self.startCollectionControllerFetching(respectingExpirationDate: false)
        }
    }
    
    @objc fileprivate func bookmarksDidChange(notification: Notification) {
        DispatchQueue.main.async {
            guard !self.isEditing else {
                return
            }
            self.startCollectionControllerFetching(respectingExpirationDate: true)
        }
    }
    
    @objc fileprivate func cherryFeaturesDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.showBannerIfAvailable()
        }
    }
    
    // MARK: - Display mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        if self.traitCollection.userInterfaceIdiom == .pad {
            self.tableView.backgroundColor = DisplayModeValue(UIColor.groupTableViewBackground, darkValue: UIColor.beamDarkBackgroundColor())
            self.tableView.sectionIndexBackgroundColor = DisplayModeValue(UIColor.groupTableViewBackground, darkValue: UIColor.beamDarkBackgroundColor())
        }
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.emptyView?.layoutMargins = self.tableView.contentInset
        //viewDidLayoutSubviews is called everytime the tableView scrolls, but we only need to know size changes
        if self.view.frame.size != self.previousViewSize && self.bannerView != nil {
            //Work around a bug  where the size of the header doesn't change
            self.tableView.tableHeaderView = nil
            self.bannerView?.sizeToFit()
            self.tableView.tableHeaderView = self.bannerView
        }
        self.previousViewSize = self.view.frame.size
    }
}

// MARK: - UITableViewDataSource

extension SubredditsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard self.emptyView == nil else {
            return 0
        }
        
        return self.content?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.content?[section].sectionName
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.content?[section].subreddits.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section: SubredditsViewControllerSection? = self.content?[(indexPath as IndexPath).section]
        let subreddit: Subreddit? = section?.subreddits[indexPath.row]
        
        let cell: SubredditTableViewCell = tableView.dequeueReusable(for: indexPath)
        cell.delegate = self
        cell.subreddit = subreddit
        return cell
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard self.emptyView == nil else {
            return nil
        }
        
        return self.content?.map { (section) -> String in
            return section.sectionName
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let sectionIndexTitles = self.sectionIndexTitles(for: tableView)
        return sectionIndexTitles?.index(of: title) ?? 0
    }
    
}

// MARK: - UITableViewDelegate

extension SubredditsViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section: SubredditsViewControllerSection? = self.content?[(indexPath as IndexPath).section]
        let subreddit: Subreddit? = section?.subreddits[indexPath.row]
        if subreddit?.isBookmarked.boolValue == true || subreddit?.isPrepopulated == true {
            return 62
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath as IndexPath).section == 0 ? 62.5: 44
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (indexPath as IndexPath).section == 0
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if let sectionObjects = self.content?[(sourceIndexPath as IndexPath).section].subreddits, (sourceIndexPath as IndexPath).section == 0 && (sourceIndexPath as IndexPath).section == (destinationIndexPath as IndexPath).section && (sourceIndexPath as IndexPath).row != (destinationIndexPath as IndexPath).row {
            
            if (destinationIndexPath as IndexPath).row > (sourceIndexPath as IndexPath).row {
                let fromIndex = (sourceIndexPath as IndexPath).row + 1
                let toIndex = (destinationIndexPath as IndexPath).row + 1
                let objectsToChange = sectionObjects[fromIndex..<toIndex]
                
                var index = fromIndex
                for object in objectsToChange {
                        object.order = NSNumber(value: index - 1)
                    index += 1
                }
                
                sectionObjects[sourceIndexPath.row].order = NSNumber(value: destinationIndexPath.row)
            } else {
                let fromIndex = (destinationIndexPath as IndexPath).row
                let toIndex = (sourceIndexPath as IndexPath).row
                let objectsToChange = sectionObjects[fromIndex..<toIndex]
                
                var index = fromIndex
                for object in objectsToChange {
                    object.order = NSNumber(value: index + 1)
                    index += 1
                }
                
                sectionObjects[sourceIndexPath.row].order = NSNumber(value: destinationIndexPath.row)
            }
            
            let context: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
            if let collection = self.collectionController.collectionID {
                let collection = context.object(with: collection) as? ObjectCollection
                self.content = self.contentFromList(collection?.objects)
            } else {
                fatalError("Collection does not exist while moving rows")
            }
            
            let saveOperations = DataController.shared.persistentSaveOperations(self.collectionController.managedObjectContext)
            DataController.shared.executeOperations(saveOperations, handler: { (error) -> Void in
                if let error = error {
                    NSLog("Could not save reordering: \(error)")
                }
            })
        }

        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section == 0 {
            return proposedDestinationIndexPath
        } else {
            if let section0 = self.content?[0] {
                return IndexPath(row: section0.subreddits.count - 1, section: 0)
            } else {
                return IndexPath(row: 0, section: 0)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let subreddit = self.content?[(indexPath as IndexPath).section].subreddits[indexPath.row] else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        //Open the subreddit
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
            tabBarController.subreddit = subreddit
            self.showDetailViewController(tabBarController, sender: indexPath)
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.hidingButtonBarDelegate?.buttonBarScrollViewDidScroll(scrollView)
    }
    
    //Editing
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if tableView.isEditing {
            return .none
        }
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if !tableView.isEditing {
            if let subreddit = self.content?[(indexPath as IndexPath).section].subreddits[indexPath.row] {
                return !subreddit.isPrepopulated && subreddit.isSubscriber?.boolValue == true
            }
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let subreddit = self.content?[indexPath.section].subreddits[indexPath.row] else {
            return nil
        }
        
        var actions = [UIContextualAction]()
        
        let title = subreddit.isBookmarked.boolValue ? "Unfavorite" : "Favorite"
        let style: UIContextualAction.Style = subreddit.isBookmarked.boolValue ? .destructive : .normal
        let favoriteAction = UIContextualAction(style: style, title: title, handler: { (_, _, callback) in
            guard !subreddit.isPrepopulated else {
                callback(false)
                return
            }
            guard let subredditToEdit: Subreddit = self.editContext?.object(with: subreddit.objectID) as? Subreddit else {
                NSLog("The subreddit to edit could not be found")
                return
            }
            
            subredditToEdit.changeBookmark(!subredditToEdit.isBookmarked.boolValue)
            if subredditToEdit.isBookmarked.boolValue {
                Trekker.default.track(event: TrekkerEvent(event: "Favorite subreddit", properties: ["View": "Subreddits list"]))
                
                subredditToEdit.order = NSNumber(value: self.content?[0].subreddits.count ?? 0)
            } else {
                subredditToEdit.order = NSNumber(value: 0)
            }
            
            do {
                try self.editContext!.save()
            } catch {
                NSLog("Could not save edit context: \(error)")
                return
            }
            
            guard let content = self.content else {
                fatalError("The content is missing when tapping a star in the list that is powered by the content, something has gone seriously wrong")
            }
            let previousSection: SubredditsViewControllerSection = content[(indexPath as IndexPath).section]
            
            self.tableView.beginUpdates()
            
            self.content = self.contentWithCollectionID(self.collectionController.collectionID)
            
            guard let newContent = self.content else {
                fatalError("Content is missing after self.contentWithCollectionID(), this should happen at all!")
            }
            
            if let newIndexPath: IndexPath = self.indexPathForSubreddit(subreddit) {
                let newSection: SubredditsViewControllerSection = newContent[(newIndexPath as IndexPath).section]
                if previousSection.subreddits.count == 1 && newSection.subreddits.count == 1 {
                    self.tableView.deleteSections(IndexSet(integer: (indexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
                    self.tableView.insertSections(IndexSet(integer: (newIndexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
                } else if previousSection.subreddits.count == 1 && newSection.subreddits.count > 1 {
                    self.tableView.deleteSections(IndexSet(integer: (indexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
                    self.tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
                } else if previousSection.subreddits.count > 1 && newSection.subreddits.count == 1 {
                    self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                    self.tableView.insertSections(IndexSet(integer: (newIndexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
                } else {
                    self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                    self.tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
                }
            } else {
                if previousSection.subreddits.count == 1 {
                    self.tableView.deleteSections(IndexSet(integer: (indexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
                } else {
                    self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                }
            }
            
            self.tableView.endUpdates()
            callback(true)
            
        })
        favoriteAction.backgroundColor = .yellow
        actions.append(favoriteAction)
        
        let config = UISwipeActionsConfiguration(actions: actions)
        config.performsFirstActionWithFullSwipe = true
        return config
        
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let subreddit = self.content?[indexPath.section].subreddits[indexPath.row] else {
            return nil
        }
        var actions = [UIContextualAction]()
        
        if !subreddit.isPrepopulated {
            let unsubscribeAction = UIContextualAction(style: .destructive, title: AWKLocalizedString("unsubscribe-button"), handler: { (_, _, callback) in
                guard let subreddits = self.content?[indexPath.section].subreddits, let index = subreddits.index(of: subreddit), !subreddit.isPrepopulated else {
                    callback(false)
                    return
                }
                
                self.content?[indexPath.section].subreddits.remove(at: index)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.unsubscribeSubreddit(subreddit, indexPath: indexPath)
                callback(true)
               
            })
            actions.append(unsubscribeAction)
        }

        let config = UISwipeActionsConfiguration(actions: actions)
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    fileprivate func unsubscribeSubreddit(_ subreddit: Subreddit, indexPath: IndexPath) {
        
        let subscribeOperations = subreddit.subscribeOperations(AppDelegate.shared.authenticationController, unsubscribe: true)
        DataController.shared.executeAndSaveOperations(subscribeOperations, context: AppDelegate.shared.managedObjectContext) { (error) -> Void in
            
            DispatchQueue.main.async(execute: { () -> Void in
                Trekker.default.track(event: TrekkerEvent(event: "Unsubscribe Subreddit", properties: ["View": "Subreddits"]))
                if let error = error {
                    let message = NSString(format: AWKLocalizedString("unsubscribe_subreddit_failure") as NSString, subreddit.displayName ?? AWKLocalizedString("subreddit"), error.localizedDescription)
                    self.presentErrorMessage(message as String)
                    self.tableView.reloadData()
                }
            })
        }
        
    }
    
}

extension SubredditsViewController: SubredditTableViewCellDelegate {
    
    func subredditTableViewCell(_ cell: SubredditTableViewCell, toggleFavoriteOnSubreddit subreddit: Subreddit) {
        guard let subredditToEdit: Subreddit = self.editContext?.object(with: subreddit.objectID) as? Subreddit else {
            NSLog("The subreddit to edit could not be found")
            return
        }
        
        subredditToEdit.changeBookmark(!subredditToEdit.isBookmarked.boolValue)
        if subredditToEdit.isBookmarked.boolValue {
            Trekker.default.track(event: TrekkerEvent(event: "Favorite subreddit", properties: ["View": "Subreddits list"]))
            
            subredditToEdit.order = NSNumber(value: self.content?[0].subreddits.count ?? 0)
        } else {
            subredditToEdit.order = NSNumber(value: 0)
        }
        
        do {
            try self.editContext!.save()
        } catch {
            NSLog("Could not save edit context: \(error)")
            return
        }
        
        guard let indexPath: IndexPath = self.tableView.indexPath(for: cell) else {
            NSLog("The cell is currently not in the tableView")
            return
        }
            
        guard let content = self.content else {
            fatalError("The content is missing when tapping a star in the list that is powered by the content, something has gone seriously wrong")
        }
        let previousSection: SubredditsViewControllerSection = content[(indexPath as IndexPath).section]
        
        self.tableView.beginUpdates()
        
        self.content = self.contentWithCollectionID(self.collectionController.collectionID)
        
        guard let newContent = self.content else {
            fatalError("Content is missing after self.contentWithCollectionID(), this should happen at all!")
        }
        
        if let newIndexPath: IndexPath = self.indexPathForSubreddit(subreddit) {
            let newSection: SubredditsViewControllerSection = newContent[(newIndexPath as IndexPath).section]
            if previousSection.subreddits.count == 1 && newSection.subreddits.count == 1 {
                self.tableView.deleteSections(IndexSet(integer: (indexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
                self.tableView.insertSections(IndexSet(integer: (newIndexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
            } else if previousSection.subreddits.count == 1 && newSection.subreddits.count > 1 {
                self.tableView.deleteSections(IndexSet(integer: (indexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
                self.tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
            } else if previousSection.subreddits.count > 1 && newSection.subreddits.count == 1 {
                self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                self.tableView.insertSections(IndexSet(integer: (newIndexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
            } else {
                self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                self.tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
            }
        } else {
            if previousSection.subreddits.count == 1 {
                self.tableView.deleteSections(IndexSet(integer: (indexPath as IndexPath).section), with: UITableViewRowAnimation.fade)
            } else {
                self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
        }
        
        self.tableView.endUpdates()
        
    }
    
}

// MARK: - CollectionControllerDelegate
extension SubredditsViewController: CollectionControllerDelegate {
    
    func collectionControllerShouldFetchMore(_ controller: CollectionController) -> Bool {
        return true
    }
    
    func collectionController(_ controller: CollectionController, collectionDidUpdateWithID objectID: NSManagedObjectID?) {
        DispatchQueue.main.async {
            self.refreshControl?.endRefreshing()
        }
    }
    
    func collectionController(_ controller: CollectionController, didUpdateStatus newStatus: CollectionControllerStatus) {
        if (newStatus == .inMemory) && controller.error == nil {
            if self.collectionHasSubreddits(collectionID: self.collectionController.collectionID) == false {
                DispatchQueue.main.async(execute: { () -> Void in
                    //Look like we didn't get any subreddits and the user is probably new, fetch the defaults for him
                    (controller.query as? SubredditsCollectionQuery)?.shouldFetchDefaults = true
                    self.startCollectionControllerFetching()
                })
            } else if let subredditsQuery = controller.query as? SubredditsCollectionQuery, subredditsQuery.shouldFetchDefaults == true {
                subredditsQuery.shouldFetchDefaults = false
            }
        } else if let subredditsQuery = controller.query as? SubredditsCollectionQuery, subredditsQuery.shouldFetchDefaults == true && newStatus == .inMemory {
            subredditsQuery.shouldFetchDefaults = false
        }
    }
    
}

@available(iOS 9, *)
extension SubredditsViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location), let cell = self.tableView.cellForRow(at: indexPath) else {
            return nil
        }
        guard let subreddit = self.content?[(indexPath as IndexPath).section].subreddits[indexPath.row] else {
            return nil
        }
        
        //Make the subreddit view controller
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
                
                tabBarController.subreddit = subreddit
                
                //Set the frame to animate the peek from
                previewingContext.sourceRect = cell.frame
                
                //Pass the view controller to display
                return tabBarController
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        //We only show subreddit view controller in this view, which is always presented modally
        self.present(viewControllerToCommit, animated: true, completion: nil)
    }
}
