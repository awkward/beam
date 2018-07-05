//
//  PostSearchResultsViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 14-06-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

class PostSearchResultsViewController: BeamViewController, HidingButtonBarDelegate {
    
    var searchKeywords: String! {
        didSet {
            if oldValue != self.searchKeywords {
                self.startFetching(self.searchKeywords)
            }
        }
    }
    
    var lastButtonBarScrollViewOffset: CGPoint?
    var lastScrollViewOffset: CGPoint?
    var lastScrollViewOffsetCapture: TimeInterval?
    @IBOutlet weak var topButtonBarConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sortingBarItem: UIBarButtonItem!
    @IBOutlet weak var sortingBar: ScrollableButtonBar!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var topButtonBarOffset: CGFloat {
        return 0
    }
    
    var streamViewController: StreamViewController? {
        return self.childViewControllers.first(where: { (viewController) -> Bool in
            viewController is StreamViewController
        }) as? StreamViewController
    }
    
    weak var query: PostCollectionQuery? {
        return self.streamViewController?.query as? PostCollectionQuery
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get {
            return true
        }
        set {
            //Do nothing
        }
    }
    
    private func setupView() {
        let storyboard = UIStoryboard(name: "Stream", bundle: nil)
        if let streamViewController = storyboard.instantiateInitialViewController() as? StreamViewController {
            streamViewController.useCompactViewMode = true
            streamViewController.refreshControl = nil
            streamViewController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
            
            self.view.insertSubview(streamViewController.view, belowSubview: self.toolbar)
            
            streamViewController.tableView.expandScrollArea()
            
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
        
        self.streamViewController?.additionalSafeAreaInsets = UIEdgeInsets(top: self.toolbar.frame.height, left: 0, bottom: 0, right: 0)
        
        if self.streamViewController?.collectionController.status == .idle {
            self.startFetching(self.searchKeywords)
        }
        
        self.streamViewController?.hidingButtonBarDelegate = self
        
        //This will also cause the stream to do the initial fetching
        self.changeSorting(.relevance, timeFrame: .allTime)
        
        self.sortingBar.items = [AWKLocalizedString("relevance"), AWKLocalizedString("top"), AWKLocalizedString("new"), AWKLocalizedString("comments")]
        self.sortingBar.selectedItemIndex = self.sortingBarIndexForSortType(CollectionSortType.defaultSortType(.postsSearch))
        self.sortingBar.addTarget(self, action: #selector(PostSearchResultsViewController.sortingBarItemTapped(_:)), for: UIControlEvents.valueChanged)
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
        query.sortType = CollectionSortType.relevance
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
            self.changeSorting(sortType, timeFrame: CollectionTimeFrame.thisHour)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-24-hours"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: CollectionTimeFrame.today)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-week"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: CollectionTimeFrame.thisWeek)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-month"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: .thisMonth)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("past-year"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: CollectionTimeFrame.thisYear)
        }))
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("all-time"), style: .default, handler: { (_) -> Void in
            self.changeSorting(sortType, timeFrame: CollectionTimeFrame.allTime)
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
}

extension PostSearchResultsViewController: NavigationBarNotificationDisplayingDelegate {
    
    func topViewForDisplayOfnotificationView<NotificationView: UIView>(_ view: NotificationView) -> UIView? where NotificationView: NavigationBarNotification {
        return self.sortingBar.superview
    }
}
