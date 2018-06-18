//
//  SubredditSearchResultsViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 10-06-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

class SubredditSearchResultsViewController: BeamViewController, HidingButtonBarDelegate {
    
    var lastButtonBarScrollViewOffset: CGPoint?
    var lastScrollViewOffset: CGPoint?
    var lastScrollViewOffsetCapture: TimeInterval?
    @IBOutlet weak var topButtonBarConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sortingBarItem: UIBarButtonItem!
    @IBOutlet weak var sortingBar: ScrollableButtonBar!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var customNavigationController: UINavigationController? {
        didSet {
            self.streamViewController?.customNavigationController = self.customNavigationController
        }
    }
    
    var streamViewController: StreamViewController? {
        return self.childViewControllers.first(where: { $0 is StreamViewController }) as? StreamViewController
    }
    
    weak var subreddit: Subreddit? {
        didSet {
            if oldValue != self.subreddit && self.streamViewController != nil {
                self.updateStreamQuery()
            }
            
        }
    }
    
    weak var query: PostCollectionQuery? {
        return self.streamViewController?.query as? PostCollectionQuery
    }
    
    override var navigationController: UINavigationController? {
        get {
            return customNavigationController
        }
        set {
            //Do nothing
        }
    }
    
    fileprivate var requestTimer: Timer?
    
    private func setupView() {
        let storyboard = UIStoryboard(name: "Stream", bundle: nil)
        if let streamViewController = storyboard.instantiateInitialViewController() as? StreamViewController {
            streamViewController.useCompactViewMode = true
            streamViewController.customNavigationController = self.customNavigationController
            streamViewController.refreshControl = nil
            streamViewController.additionalSafeAreaInsets = UIEdgeInsets(top: toolbar.frame.height, left: 0, bottom: 0, right: 0)
            streamViewController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
            
            self.view.insertSubview(streamViewController.view, belowSubview: self.toolbar)
            self.addChildViewController(streamViewController)
            
            streamViewController.view.translatesAutoresizingMaskIntoConstraints = false
            //Add horizontal constraints to make the view center with a max width
            self.view.addConstraint(NSLayoutConstraint(item: streamViewController.view, attribute: .leading, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: streamViewController.view, attribute: .trailing, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: streamViewController.view, attribute: .centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0))
            streamViewController.view.addConstraint(NSLayoutConstraint(item: streamViewController.view, attribute: .width, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIView.MaximumViewportWidth))
            
            //Limit the actual width, but give it a lower priority (750) so that it can be smaller if it needs to be (on iPhone for example)
            let widthConstraint = NSLayoutConstraint(item: streamViewController.view, attribute: .width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: UIView.MaximumViewportWidth)
            widthConstraint.priority = UILayoutPriority.defaultHigh
            streamViewController.view.addConstraint(widthConstraint)
            
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[viewController]|", options: [], metrics: nil, views: ["viewController": streamViewController.view]))
            
            //Disable the scrollbar on iPad, it looks weird
            if let tableView = streamViewController.view as? UITableView, UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                tableView.showsVerticalScrollIndicator = false
            }
            
            streamViewController.didMove(toParentViewController: self)
            
            self.updateStreamQuery()
        } else {
            fatalError("StreamViewController should be in Stream storyboard.")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        
        self.streamViewController?.hidingButtonBarDelegate = self
        
        //This will also cause the stream to do the initial fetching
        self.changeSorting(CollectionSortType.relevance, timeFrame: CollectionTimeFrame.allTime)
        
        self.sortingBar.items = [AWKLocalizedString("relevance"), AWKLocalizedString("top"), AWKLocalizedString("new"), AWKLocalizedString("comments")]
        self.sortingBar.selectedItemIndex = self.sortingBarIndexForSortType(CollectionSortType.defaultSortType(CollectionSortContext.postsSearch))
        self.sortingBar.addTarget(self, action: #selector(SubredditSearchResultsViewController.sortingBarItemTapped(_:)), for: UIControlEvents.valueChanged)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.sortingBarItem.width = self.view.bounds.width
    }
    
    // MARK: - Query
    
    func updateStreamQuery() {
        let query = PostCollectionQuery()
        query.searchKeywords = self.streamViewController?.query?.searchKeywords ?? ""
        query.sortType = .relevance
        query.subreddit = self.subreddit
        query.hideNSFWContent = !AppDelegate.shared.authenticationController.userCanViewNSFWContent
        self.streamViewController?.query = query
    }
    
    // MARK: - Data
    
    func startFetching(_ searchText: String? = nil) {
        self.streamViewController?.cancelCollectionControllerFetching()
        if let searchText = searchText, searchText.count > 0 {
            self.query?.searchKeywords = searchText
        }
        self.streamViewController?.startCollectionControllerFetching()
    }
    
    // MARK: - Actions
    
    @objc fileprivate func sortingBarItemTapped(_ sortingBar: ScrollableButtonBar) {
        if let index = sortingBar.selectedItemIndex {
            let sortType = self.sortTypeForSortingBarIndex(index)
            if sortType.supportsTimeFrame(CollectionSortContext.postsSearch) {
                self.showTimeFrameActionSheet(sortType, sortingBar: sortingBar)
            } else {
                let timeFrame = CollectionTimeFrame.allTime
                self.changeSorting(sortType, timeFrame: timeFrame)
            }
        }
    }
    
    fileprivate func showTimeFrameActionSheet(_ sortType: CollectionSortType, sortingBar: ScrollableButtonBar) {
        let alertController = BeamAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-hour"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .thisHour)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-24-hours"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .today)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-week"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .thisWeek)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-month"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .thisMonth)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-year"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .thisYear)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("all-time"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .allTime)
        }))
        alertController.addCancelAction { (_) in
            self.sortingBar.selectedItemIndex = self.sortingBarIndexForSortType(self.streamViewController?.query?.sortType ?? CollectionSortType.relevance)
        }
        
        alertController.popoverPresentationController?.sourceView = sortingBar
        alertController.popoverPresentationController?.sourceRect = sortingBar.buttonFrameForSelectedItemIndex() ?? sortingBar.frame
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func sortingBarIndexForSortType(_ sortType: CollectionSortType) -> Int {
        switch sortType {
        case .relevance:
            return 0
        case .top:
            return 1
        case .new:
            return 2
        case .comments:
            return 3
        default:
            return 0
        }
    }
    
    fileprivate func sortTypeForSortingBarIndex(_ index: Int) -> CollectionSortType {
        switch index {
        case 0:
            return .relevance
        case 1:
            return .top
        case 2:
            return .new
        case 3:
            return .comments
        default:
            return .relevance
        }
    }
    
    fileprivate func changeSorting(_ sorting: CollectionSortType, timeFrame: CollectionTimeFrame) {
        guard let query = self.streamViewController?.query as? PostCollectionQuery else {
            return
        }
        
        //Make sure the view is empty before loading
        self.streamViewController?.content = nil
        self.streamViewController?.collectionController.clear()
        
        query.sortType = sorting
        query.timeFrame = timeFrame
        
        self.startFetching()
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        switch displayMode {
        case .default:
            self.toolbar.barTintColor = UIColor.beamBarColor()
        case .dark:
            self.toolbar.barTintColor = UIColor.beamDarkContentBackgroundColor()
        }
    }
    
    // MARK: - Request timer
    
    fileprivate func startRequestTimer() {
        self.invalidateRequestTimer()
        self.requestTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(SubredditSearchResultsViewController.requestTimerFired(_:)), userInfo: nil, repeats: false)
    }
    
    fileprivate func invalidateRequestTimer() {
        if let timer = self.requestTimer {
            timer.invalidate()
        }
        
        self.requestTimer = nil
    }
    
    @objc fileprivate func requestTimerFired(_ timer: Timer) {
        self.invalidateRequestTimer()
        self.startFetching()
    }
    
}

extension SubredditSearchResultsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        var searchText = searchController.searchBar.text
        //Make sure search text is never nil!
        if searchText == nil || searchText?.count == 0 {
            searchText = ""
        }
        
        if searchText != self.query?.searchKeywords {
            self.streamViewController?.content = nil
            
            self.query?.searchKeywords = searchText
            
            self.startRequestTimer()
        }
    }
    
}

// MARK: - UIToolbarDelegate
extension SubredditSearchResultsViewController: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
}

extension SubredditSearchResultsViewController: NavigationBarNotificationDisplayingDelegate {
    
    func topViewForDisplayOfnotificationView<NotificationView: UIView>(_ view: NotificationView) -> UIView? where NotificationView: NavigationBarNotification {
        return self.sortingBar.superview
    }
}
