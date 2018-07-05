//
//  SubredditStreamViewController.swift
//  beam
//
//  Created by Robin Speijer on 25-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import Trekker

class SubredditStreamViewController: BeamViewController, SubredditTabItemViewController, HidingButtonBarDelegate {
    
    weak var multiredditsEmptyState: BeamEmptyView?
    
    var lastButtonBarScrollViewOffset: CGPoint?
    var lastScrollViewOffset: CGPoint?
    var lastScrollViewOffsetCapture: TimeInterval?
    @IBOutlet weak var topButtonBarConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sortingBarItem: UIBarButtonItem!
    @IBOutlet weak var sortingBar: ScrollableButtonBar!
    @IBOutlet weak var toolbar: UIToolbar!
    
    fileprivate var trackedVisitEvent = false
    
    var streamViewController: StreamViewController? {
        return self.childViewControllers.first(where: { $0 is StreamViewController }) as? StreamViewController
    }
    
    var titleView: SubredditTitleView = SubredditTitleView.titleViewWithSubreddit(nil)
    
    weak var subreddit: Subreddit? {
        didSet {
            self.updateNavigationItem()
            if oldValue != nil {
                self.updateStreamQuery()
            }
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadEmptyState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.trackedVisitEvent == false {
            var subredditName = "Other"
            if self.subreddit?.identifier == Subreddit.frontpageIdentifier {
                subredditName = "Frontpage"
            } else if self.subreddit?.identifier == Subreddit.allIdentifier {
                subredditName = "All"
            } else {
                
            }
            let properties = ["Subreddit": subredditName]
            Trekker.default.track(event: TrekkerEvent(event: "Visit subreddit", properties: properties))
            self.trackedVisitEvent = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        
        self.updateNavigationItem()
        
        self.streamViewController?.hidingButtonBarDelegate = self
        
        self.changeSorting(self.subreddit?.streamSortType ?? .hot, timeFrame: self.subreddit?.streamTimeFrame ?? .thisMonth)
        
        self.sortingBar.items = [AWKLocalizedString("hot"), AWKLocalizedString("new"), AWKLocalizedString("rising"), AWKLocalizedString("controversial"), AWKLocalizedString("top"), AWKLocalizedString("gilded")]
        self.sortingBar.selectedItemIndex = self.sortingBarIndexForSortType(self.subreddit?.streamSortType ?? .hot)
        self.sortingBar.addTarget(self, action: #selector(SubredditStreamViewController.sortingBarItemTapped(_:)), for: UIControlEvents.valueChanged)
        
        self.streamViewController?.additionalSafeAreaInsets = UIEdgeInsets(top: self.toolbar.frame.height, left: 0, bottom: 0, right: 0)
    }
    
    private func setupView() {
        let storyboard = UIStoryboard(name: "Stream", bundle: nil)
        if let streamviewController = storyboard.instantiateInitialViewController() as? StreamViewController {
            streamviewController.streamDelegate = self
            
            self.multiredditsEmptyState = BeamEmptyView.emptyView(.MultiredditNoSubreddits, frame: CGRect())
            
            self.view.insertSubview(self.multiredditsEmptyState!, belowSubview: self.toolbar)
            self.multiredditsEmptyState!.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[emptyState]|", options: [], metrics: nil, views: ["emptyState": self.multiredditsEmptyState!]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[emptyState]|", options: [], metrics: nil, views: ["emptyState": self.multiredditsEmptyState!]))
            self.view.insertSubview(streamviewController.view, belowSubview: self.multiredditsEmptyState!)
            
            streamviewController.tableView.expandScrollArea()
            
            self.multiredditsEmptyState!.buttonHandler = { [weak self] (button) -> Void in
                self?.addMultiredditSubs(nil)
            }
            
            self.addChildViewController(streamviewController)
            
            streamviewController.view.translatesAutoresizingMaskIntoConstraints = false
            //Add horizontal constraints to make the view center with a max width
            self.view.addConstraint(NSLayoutConstraint(item: streamviewController.view, attribute: .leading, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: streamviewController.view, attribute: .trailing, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: streamviewController.view, attribute: .centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0))
            streamviewController.view.addConstraint(NSLayoutConstraint(item: streamviewController.view, attribute: .width, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIView.MaximumViewportWidth))
            
            //Limit the actual width, but give it a lower priority (750) so that it can be smaller if it needs to be (on iPhone for example)
            let widthConstraint = NSLayoutConstraint(item: streamviewController.view, attribute: .width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: UIView.MaximumViewportWidth)
            widthConstraint.priority = UILayoutPriority.defaultHigh
            streamviewController.view.addConstraint(widthConstraint)
            
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[viewController]|", options: [], metrics: nil, views: ["viewController": streamviewController.view]))
            
            //Disable the scrollbar on iPad, it looks weird
            if let tableView = streamviewController.view as? UITableView, UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                tableView.showsVerticalScrollIndicator = false
            }
            
            streamviewController.didMove(toParentViewController: self)
        } else {
            fatalError("StreamViewController should be in Stream storyboard.")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateStreamQuery(_ sortType: CollectionSortType? = nil, timeFrame: CollectionTimeFrame? = nil) {
        //Only update if the query was already set
        let currentQuery: PostCollectionQuery? = self.streamViewController?.query as? PostCollectionQuery
        let query: PostCollectionQuery = PostCollectionQuery()
        
        var newSortType: CollectionSortType!
        var newTimeFrame: CollectionTimeFrame!
        if let sortType: CollectionSortType = sortType, let timeFrame: CollectionTimeFrame = timeFrame {
            newSortType = sortType
            newTimeFrame = timeFrame
        } else {
            if let currentSortType: CollectionSortType = currentQuery?.sortType, let currentTimeFrame: CollectionTimeFrame = currentQuery?.timeFrame {
                newSortType = currentSortType
                newTimeFrame = currentTimeFrame
            } else {
                newSortType = self.subreddit?.streamSortType
                newTimeFrame = self.subreddit?.streamTimeFrame
            }
            if newSortType == nil {
                newSortType = .hot
            }
            if newTimeFrame == nil {
                newTimeFrame = .thisMonth
            }
        }
        query.sortType = newSortType
        query.timeFrame = newTimeFrame
        
        query.subreddit = self.subreddit
        query.hideNSFWContent = !AppDelegate.shared.authenticationController.userCanViewNSFWContent

        self.streamViewController?.query = query
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.sortingBarItem.width = self.view.bounds.width
    }
    
    // MARK: - Actions
    
    @IBAction func addMultiredditSubs(_ sender: AnyObject?) {
        self.tabBarController?.performSegue(withIdentifier: "manageMultireddit", sender: self)
    }
    
    @objc fileprivate func sortingBarItemTapped(_ sortingBar: ScrollableButtonBar) {
        if let index = sortingBar.selectedItemIndex {
            let sortType = self.sortTypeForSortingBarIndex(index)
            if sortType.supportsTimeFrame(.posts) {
                self.showTimeFrameActionSheet(sortType, sortingBar: sortingBar)
            } else {
                let timeFrame = (sortType == CollectionSortType.hot) ? CollectionTimeFrame.thisMonth: CollectionTimeFrame.allTime
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
            self.sortingBar.selectedItemIndex = self.sortingBarIndexForSortType(self.streamViewController?.query?.sortType ?? .hot)
        }
        
        alertController.popoverPresentationController?.sourceView = sortingBar
        alertController.popoverPresentationController?.sourceRect = sortingBar.buttonFrameForSelectedItemIndex() ?? sortingBar.frame
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func sortingBarIndexForSortType(_ sortType: CollectionSortType) -> Int {
        switch sortType {
        case .hot:
            return 0
        case .new:
            return 1
        case .rising:
            return 2
        case .controversial:
            return 3
        case .top:
            return 4
        case .gilded:
            return 5
        default:
            return 0
        }
    }
    
    fileprivate func sortTypeForSortingBarIndex(_ index: Int) -> CollectionSortType {
        switch index {
        case 1:
            return .new
        case 2:
            return .rising
        case 3:
            return .controversial
        case 4:
            return .top
        case 5:
            return .gilded
        default:
            return .hot
        }
    }
    
    fileprivate func changeSorting(_ sorting: CollectionSortType, timeFrame: CollectionTimeFrame) {
        
        self.subreddit?.streamSortType = sorting
        self.subreddit?.streamTimeFrame = timeFrame
        
        self.updateStreamQuery(sorting, timeFrame: timeFrame)
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
    
    fileprivate func reloadEmptyState() {
        let isEmpty = (subreddit is Multireddit && (subreddit as! Multireddit).subreddits?.count == 0)
        self.multiredditsEmptyState?.isHidden = !isEmpty
        self.streamViewController?.view.isHidden = isEmpty
        self.streamViewController?.tableView.isScrollEnabled = !isEmpty
    }

}

// MARK: - UIToolbarDelegate
extension SubredditStreamViewController: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
    
}

extension SubredditStreamViewController: NavigationBarNotificationDisplayingDelegate {

    func topViewForDisplayOfnotificationView<NotificationView: UIView>(_ view: NotificationView) -> UIView? where NotificationView: NavigationBarNotification {
        return self.sortingBar.superview
    }
}

extension SubredditStreamViewController: StreamViewControllerDelegate {
    
    func streamViewController(_ viewController: StreamViewController, didChangeContent content: [Content]?) {
        self.reloadEmptyState()
    }
}
