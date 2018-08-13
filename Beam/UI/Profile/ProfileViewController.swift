//
//  ProfileViewController.swift
//  beam
//
//  Created by Robin Speijer on 30-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import SafariServices
import CoreData
import Trekker

private enum ProfileHeaderState {
    case full
    case bar
}

struct ProfileContentSection {
    var title: String
    var stream: StreamViewController
    let type: UserContentType
    
    init(type: UserContentType, stream: StreamViewController) {
        self.type = type
        self.stream = stream
        
        switch type {
        case .submitted:
            self.title = AWKLocalizedString("submitted")
        case .upvoted:
            self.title = AWKLocalizedString("upvoted")
        case .saved:
            self.title = AWKLocalizedString("saved")
        case .hidden:
            self.title = AWKLocalizedString("hidden")
        case .overview:
            self.title = AWKLocalizedString("overview")
        case .comments:
            self.title = AWKLocalizedString("comments")
        case .gilded:
            self.title = AWKLocalizedString("gilded")
        default:
            self.title = ""
        }
    }
}

class ProfileViewController: BeamViewController {
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var buttonBarItem: UIBarButtonItem!
    @IBOutlet weak var buttonBar: ScrollableButtonBar!
    
    fileprivate var headerState = ProfileHeaderState.full
    
    @IBOutlet var linkKarmaLabel: UILabel!
    @IBOutlet var linkKarmaDescriptionLabel: UILabel!
    @IBOutlet var commentKarmaLabel: UILabel!
    @IBOutlet var commentKarmaDescriptionLabel: UILabel!
    @IBOutlet var headerView: UIView!
    @IBOutlet var topButtonBarConstraint: NSLayoutConstraint!
    
    var previousSection: ProfileContentSection?
    
    var lastButtonBarScrollViewOffset: CGPoint?
    var lastScrollViewOffset: CGPoint?
    var lastScrollViewOffsetCapture: TimeInterval?
    
    var touchForwardingView: TouchesForwardingView?
    
    // MARK: - Paging
    
    func streamViewControllerWithContentType(_ contentType: UserContentType) -> StreamViewController {
        if let viewController = UIStoryboard(name: "Stream", bundle: nil).instantiateInitialViewController() as? StreamViewController {
            if let query = self.userContentCollectionQueryWithContentType(contentType) {
                viewController.query = query
            }
            
            let isOtherUser = !(self is CurrentUserProfileViewController)
            
            if contentType == UserContentType.submitted || contentType == UserContentType.overview {
                viewController.defaultEmptyViewType = isOtherUser ? BeamEmptyViewType.OtherProfileNoPostsSubmitted: BeamEmptyViewType.ProfileNoPostsSubmitted
            } else if contentType == UserContentType.upvoted {
                viewController.defaultEmptyViewType = BeamEmptyViewType.ProfileNoPostsLiked
            } else if contentType == UserContentType.saved {
                viewController.defaultEmptyViewType = BeamEmptyViewType.ProfileNoPostsSaved
            } else if contentType == UserContentType.hidden {
                viewController.defaultEmptyViewType = BeamEmptyViewType.ProfileNoPostsHidden
            } else if contentType == UserContentType.comments {
                viewController.defaultEmptyViewType = isOtherUser ? BeamEmptyViewType.OtherProfileNoComments: BeamEmptyViewType.ProfileNoComments
            } else if contentType == UserContentType.gilded {
                viewController.defaultEmptyViewType = isOtherUser ? BeamEmptyViewType.OtherProfileNoGilded: BeamEmptyViewType.ProfileNoGilded
            }
            
            viewController.hidingButtonBarDelegate = self
            return viewController
        } else {
            fatalError("StreamViewController should be in Stream storyboard.")
        }
    }
    
    func userContentCollectionQueryWithContentType(_ contentType: UserContentType) -> UserContentCollectionQuery? {
        if let userIdentifier = self.user?.identifier {
            let query = UserContentCollectionQuery(userIdentifier: userIdentifier)
            query.userContentType = contentType
            query.hideNSFWContent = !AppDelegate.shared.authenticationController.userCanViewNSFWContent
            return query
        }
        return nil
    }
    
    lazy var sections: [ProfileContentSection] = {
        return [ProfileContentSection(type: .overview, stream: self.streamViewControllerWithContentType(UserContentType.overview)),
            ProfileContentSection(type: .comments, stream: self.streamViewControllerWithContentType(UserContentType.comments)),
            ProfileContentSection(type: .submitted, stream: self.streamViewControllerWithContentType(UserContentType.submitted)),
            ProfileContentSection(type: .gilded, stream: self.streamViewControllerWithContentType(UserContentType.gilded))]
    }()
    
    var currentSection: ProfileContentSection {
        return self.sections[self.buttonBar.selectedItemIndex ?? 0]
    }
    
    func updateSectionQueries() {
        for section in self.sections {
            if let query = self.userContentCollectionQueryWithContentType(section.type) {
                section.stream.query = query
            }
        }
    }
    
    func updateNSFWContentFlags() {
        for section in self.sections {
            if let query = section.stream.query as? UserContentCollectionQuery {
                query.hideNSFWContent = !AppDelegate.shared.authenticationController.userCanViewNSFWContent
            }
        }
    }
    
    func updateSectionVisibilities() {
        guard self.previousSection?.type != self.currentSection.type else {
            return
        }
        if let previousSection = self.previousSection, previousSection.type != currentSection.type {
            previousSection.stream.willMove(toParentViewController: nil)
            previousSection.stream.view.removeFromSuperview()
            previousSection.stream.removeFromParentViewController()
            previousSection.stream.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 20, height: 20), animated: true)
        }
        
        //Scroll the view to the top
        self.headerState = .full
        self.topButtonBarConstraint.constant = 100
        self.view.layoutIfNeeded()
        self.currentSection.stream.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 20, height: 20), animated: true)

        self.currentSection.stream.additionalSafeAreaInsets = UIEdgeInsets(top: self.headerView.frame.height + self.toolbar.frame.height, left: 0, bottom: 0, right: 0)
        
        self.currentSection.stream.willMove(toParentViewController: self)
        self.view.addSubview(self.currentSection.stream.view)
        self.view.sendSubview(toBack: self.currentSection.stream.view)
        
        if self.touchForwardingView == nil {
            self.touchForwardingView = self.currentSection.stream.tableView.expandScrollArea()
        } else {
            self.touchForwardingView?.receivingView = self.currentSection.stream.view
        }
        
        //The touchforwarding view needs to be the lowest view
        if let forwardingView = self.touchForwardingView {
            self.view.sendSubview(toBack: forwardingView)
        }

        let streamView = self.currentSection.stream.view!
        streamView.translatesAutoresizingMaskIntoConstraints = false
        //Add horizontal constraints to make the view center with a max width
        self.view.addConstraint(NSLayoutConstraint(item: streamView, attribute: .leading, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: streamView, attribute: .trailing, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: streamView, attribute: .centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0))
        streamView.addConstraint(NSLayoutConstraint(item: streamView, attribute: .width, relatedBy: NSLayoutRelation.lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIView.MaximumViewportWidth))
        
        //Limit the actual width, but give it a lower priority (750) so that it can be smaller if it needs to be (on iPhone for example)
        let widthConstraint = NSLayoutConstraint(item: streamView, attribute: .width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: UIView.MaximumViewportWidth)
        widthConstraint.priority = UILayoutPriority.defaultHigh
        streamView.addConstraint(widthConstraint)
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[viewController]|", options: [], metrics: nil, views: ["viewController": streamView]))
        
        //Disable the scrollbar on iPad, it looks weird
        if let tableView = streamView as? UITableView, UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            tableView.showsVerticalScrollIndicator = false
        }
        
        self.addChildViewController(self.currentSection.stream)
        self.previousSection = self.currentSection
        
        self.currentSection.stream.didMove(toParentViewController: self)
        
    }
    
    // MARK: - User data
    
    var username: String? {
        didSet {
            if self.user == nil && self.username != nil {
                let userRequest = RedditUserRequest(authenticationController: AppDelegate.shared.authenticationController)
                userRequest.username = username
                let userParser = UserParsingOperation()
                userParser.addDependency(userRequest)
                
                DataController.shared.executeAndSaveOperations([userRequest, userParser], context: userParser.objectContext ) { (error: Error?) -> Void in
                    if let error = error as NSError? {
                        if self.presentingViewController != nil && error.code == 404 {
                            let presentingViewController = self.presentingViewController
                            self.dismiss(animated: true, completion: { () -> Void in
                               let alertController = BeamAlertController(alertWithCloseButtonAndTitle: AWKLocalizedString("user-not-found"), message: AWKLocalizedString("user-not-found-message"))
                                presentingViewController?.present(alertController, animated: true, completion: nil)
                            })
                        }
                    } else {
                        let mainContext: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
                        mainContext.perform {
                            if let userID = userParser.userID {
                                let newUser = mainContext.object(with: userID) as! User
                                self.user = newUser
                            } else {
                                AWKDebugLog("Profile: No user identifier for username")
                            }
                        }
                    }
                }
            }
            self.updateTitle()
        }
    }
    
    var user: User? {
        didSet {
            if self.user != oldValue {
                DispatchQueue.main.async { () -> Void in
                    self.updateSectionQueries()
                }
            }
            DispatchQueue.main.async { () -> Void in
                if !(self is CurrentUserProfileViewController) {
                    self.navigationItem.rightBarButtonItem?.isEnabled = self.user != nil
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
                
                self.username = self.user?.username
                
                self.linkKarmaLabel.attributedText = self.karmaStringFromValue(self.user?.linkKarmaCount?.intValue)
                self.commentKarmaLabel.attributedText = self.karmaStringFromValue(self.user?.commentKarmaCount?.intValue)
            }
            
        }
    }
    
    lazy var karmaNumberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.locale = Locale.current
        return numberFormatter
    }()
    
    internal func karmaStringFromValue(_ value: Int?) -> NSAttributedString {
        
        // Get the full padded string and replace the correct character with a group separator, if not already done.
        let numberString = self.karmaNumberFormatter.string(from: NSNumber(value: value ?? 0 as Int)) ?? "0000000"
        
        var paddingString = ""
        if numberString.count < 7 {
            for _ in 1...(7 - numberString.count) {
                paddingString += "0"
            }
        }
        
        let numberAttributedString = NSMutableAttributedString(string: numberString, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        let paddingAttributedString = NSMutableAttributedString(string: paddingString, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white.withAlphaComponent(0.3)])
        let attributedString = NSMutableAttributedString(attributedString: paddingAttributedString)
        attributedString.append(numberAttributedString)
        
        return attributedString
        
    }
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Only show the message compose button if the view is the profile of someone else
        if !(self is CurrentUserProfileViewController) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "compose_icon"), style: .plain, target: self, action: #selector(ProfileViewController.composeMessageTapped(sender:)))
            self.navigationItem.rightBarButtonItem?.isEnabled = self.user != nil
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: NSLocalizedString("navigation-item-back", comment: "A generic back button, in case the previous view title isn't wanted"), style: .plain, target: nil, action: nil)
        
        if let colorizedNavigationController = self.navigationController as? BeamColorizedNavigationController, self.isModallyPresentedRootViewController() {
            colorizedNavigationController.usesRoundedCorners = UIDevice.current.userInterfaceIdiom == .phone
        }
        
        self.updateTitle()
        
        self.linkKarmaLabel.attributedText = self.karmaStringFromValue(self.user?.commentKarmaCount?.intValue ?? 0)
        self.commentKarmaLabel.attributedText = self.karmaStringFromValue(self.user?.commentKarmaCount?.intValue ?? 0)
        
        self.linkKarmaDescriptionLabel.text = AWKLocalizedString("link-karma-description")
        self.commentKarmaDescriptionLabel.text = AWKLocalizedString("comment-karma-description")
        
        self.updateSectionVisibilities()
        
        if self.isModallyPresentedRootViewController() {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_close"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(UIViewController.dismissViewController(_:)))
        }
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.buttonBar.items = self.sections.map({ $0.title })
        self.buttonBar.addTarget(self, action: #selector(ProfileViewController.buttonBarChanged(_:)), for: UIControlEvents.valueChanged)
        self.buttonBar.selectedItemIndex = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.userDidChange(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: AppDelegate.shared.authenticationController)
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.userDidChange(_:)), name: AuthenticationController.UserDidUpdateNotificationName, object: AppDelegate.shared.authenticationController)
    }
    
    func updateTitle() {
        self.title = self.username ?? AWKLocalizedString("profile-title")
    }
    
    @objc func userDidChange(_ notification: Notification?) {
        DispatchQueue.main.async { () -> Void in
            self.updateNSFWContentFlags()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateSectionVisibilities()
        
        if self.presentedViewController == nil {
            if self is CurrentUserProfileViewController {
               Trekker.default.track(event: TrekkerEvent(event: "View profile"))
            }
            
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.buttonBarItem.width = self.view.bounds.width
    }
    
    // MARK: - Layout
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        switch displayMode {
        case .dark:
            headerView.backgroundColor = UIColor.beamDarkContentBackgroundColor()
        case .default:
            headerView.backgroundColor = UIColor.beamPurple()
        }
    }
    
    // MARK: - Actions
    
    @objc internal func buttonBarChanged(_ sender: ScrollableButtonBar) {
        self.updateSectionVisibilities()
        self.buttonBarScrollViewDidScroll(self.currentSection.stream.tableView)
    }

    @objc fileprivate func composeMessageTapped(sender: UIBarButtonItem) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.ComposeMessage), animated: true, completion: nil)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: "compose-message") as? UINavigationController,
            let composeViewController: RedditMessageComposeViewController = navigationController.topViewController as? RedditMessageComposeViewController,
            let user = user else {
            return
        }
        composeViewController.user = user
        self.present(navigationController, animated: true, completion: nil)
    }
    
}

extension ProfileViewController: BeamModalPresentation {
    
    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return BeamModalPresentationStyle.formsheet
    }
}

// MARK: - HidingToolbarDelegate
extension ProfileViewController: HidingButtonBarDelegate {
    
    func buttonBarScrollViewDidScroll(_ scrollView: UIScrollView) {
        let headerHeight: CGFloat = 100
        
        guard self.currentSection.stream.emptyView == nil && self.currentSection.stream.loadingState != .loading else {
            return
        }
        
        switch headerState {
        case .full:
            if scrollView.contentOffset.y < self.headerView.bounds.height + self.toolbar.bounds.height {
                let newOffset = min(headerHeight, -1 * scrollView.contentInset.top - scrollView.contentOffset.y + headerHeight)
                headerState = .full
                topButtonBarConstraint.constant = newOffset
                
            } else {
                headerState = .bar
                topButtonBarConstraint.constant = -1 * headerView.bounds.height - toolbar.bounds.height
            }
        case .bar:
            if scrollView.contentOffset.y < -1 * toolbar.bounds.height {
                let newOffset = min(headerView.bounds.height + toolbar.bounds.height, -1 * scrollView.contentInset.top - scrollView.contentOffset.y)
                headerState = .full
                topButtonBarConstraint.constant = newOffset
            } else {
                if lastButtonBarScrollViewOffset == nil {
                    lastButtonBarScrollViewOffset = scrollView.contentOffset
                }
                let delta = scrollView.contentOffset.y - (self.lastButtonBarScrollViewOffset?.y ?? (-1 * scrollView.contentInset.top))
                
                var newOffset = topButtonBarConstraint.constant - delta
                if newOffset > -1 * headerView.bounds.height {
                    newOffset = -1 * headerView.bounds.height
                } else if newOffset < -1 * headerView.bounds.height - toolbar.bounds.height {
                    newOffset = -1 * headerView.bounds.height - toolbar.bounds.height
                }
                
                topButtonBarConstraint.constant = newOffset
                lastButtonBarScrollViewOffset = scrollView.contentOffset
            }

        }
        
        let headerControlAlpha = max(0, topButtonBarConstraint.constant / headerHeight)
        linkKarmaLabel.alpha = headerControlAlpha
        linkKarmaDescriptionLabel.alpha = headerControlAlpha
        commentKarmaLabel.alpha = headerControlAlpha
        commentKarmaDescriptionLabel.alpha = headerControlAlpha
        
    }
    
    func buttonBarScrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            self.headerState = .full
            self.topButtonBarConstraint.constant = 100
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
}

extension ProfileViewController: NavigationBarNotificationDisplayingDelegate {
    
    func topViewForDisplayOfnotificationView<NotificationView: UIView>(_ view: NotificationView) -> UIView? where NotificationView: NavigationBarNotification {
        return self.buttonBar.superview
    }
}

// MARK: - UIToolbarDelegate
extension ProfileViewController: UIToolbarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.top
    }
}
