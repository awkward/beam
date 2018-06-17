//
//  SubredditInfoViewController.swift
//  beam
//
//  Created by Robin Speijer on 07-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import RedditMarkdownKit
import TTTAttributedLabel
import CherryKit
import Trekker
import CoreData

enum SubredditInfoSectionType {
    case multireddit
    case description
    case actions
    case options
    case destruction
    case settings
    
    var title: String? {
        switch self {
        case SubredditInfoSectionType.description:
            return AWKLocalizedString("subreddit-info-header-description")
        default:
            return nil
        }
    }
}

enum SubredditInfoRowType {
    //Multireddit
    case manageSubreddits
    case edit
    //Description
    case description
    //Actions
    case subscribe
    case favorite
    case addToMultireddit
    case share
    case openInSafari
    //Options
    case displayOptions
    case contentFiltering
    //Destruction
    case `private`
    case delete
    case unsubscribe
    //Settings
    case privacyOverlay
    case spoilerOverlay
    
    var textColor: UIColor {
        if self.isAction {
            if self == SubredditInfoRowType.delete {
                return DisplayModeValue(UIColor(red: 214 / 255.0, green: 64 / 255.0, blue: 64 / 255.0, alpha: 1), darkValue: UIColor(red: 214 / 255.0, green: 86 / 255.0, blue: 86 / 255.0, alpha: 1))
            }
            return DisplayModeValue(UIColor.beamColor(), darkValue: UIColor.beamPurpleLight())
        }
        return DisplayModeValue(UIColor.black, darkValue: UIColor.white)
    }
    
    var isAction: Bool {
        switch self {
        case SubredditInfoRowType.manageSubreddits,
             SubredditInfoRowType.edit,
             SubredditInfoRowType.subscribe,
             SubredditInfoRowType.favorite,
             SubredditInfoRowType.addToMultireddit,
             SubredditInfoRowType.share,
             SubredditInfoRowType.openInSafari,
             SubredditInfoRowType.delete,
             SubredditInfoRowType.unsubscribe:
            return true
        default:
            return false
        }
    }
    
    var accessoryType: UITableViewCellAccessoryType {
        switch self {
        case SubredditInfoRowType.displayOptions, SubredditInfoRowType.contentFiltering:
            return UITableViewCellAccessoryType.disclosureIndicator
        default:
            return UITableViewCellAccessoryType.none
        }
    }
    
    func iconForSubreddit(_ subreddit: Subreddit?) -> UIImage? {
        switch self {
        case SubredditInfoRowType.favorite:
            if subreddit?.isBookmarked == true {
                return UIImage(named: "subreddit_info_favorite_filled")
            } else {
                return UIImage(named: "subreddit_info_favorite")
            }
        case SubredditInfoRowType.subscribe:
            return UIImage(named: "subreddit_info_subscribe")
        case SubredditInfoRowType.unsubscribe:
            return UIImage(named: "subreddit_info_subscribed")
        case SubredditInfoRowType.addToMultireddit:
            return UIImage(named: "subreddit_info_multireddit")
        case SubredditInfoRowType.share:
            return UIImage(named: "subreddit_info_share")
        case SubredditInfoRowType.openInSafari:
            return UIImage(named: "sunreddit_info_open_in_safari")
        default:
            return nil
        }
    }
    
    func titleForSubreddit(_ subreddit: Subreddit?) -> String {
        switch self {
        case SubredditInfoRowType.manageSubreddits:
            return AWKLocalizedString("manage-subreddits")
        case SubredditInfoRowType.edit:
            return AWKLocalizedString("edit-name-and-description")
        case SubredditInfoRowType.favorite:
            if subreddit?.isBookmarked == true {
                return AWKLocalizedString("remove-from-favorites")
            } else {
                return AWKLocalizedString("add-to-favorites")
            }
        case SubredditInfoRowType.openInSafari:
            return AWKLocalizedString("open-in-safari")
        case SubredditInfoRowType.addToMultireddit:
            return AWKLocalizedString("add-to-multireddit")
        case SubredditInfoRowType.share:
            return AWKLocalizedString("share")
        case SubredditInfoRowType.private:
            return AWKLocalizedString("private").capitalized(with: NSLocale.current)
        case SubredditInfoRowType.delete:
            return AWKLocalizedString("delete")
        case SubredditInfoRowType.displayOptions:
            return AWKLocalizedString("display-options-setting-title")
        case SubredditInfoRowType.contentFiltering:
            return NSLocalizedString("content-filtering-setting-title", comment: "The content filtering subreddit setting")
        case SubredditInfoRowType.unsubscribe:
            return AWKLocalizedString("unsubscribe-button")
        case SubredditInfoRowType.spoilerOverlay:
            return AWKLocalizedString("show-spoiler-overlay")
        case SubredditInfoRowType.privacyOverlay:
            return AWKLocalizedString("show-privacy-overlay")
        case SubredditInfoRowType.subscribe:
            return AWKLocalizedString("subscribe-button")
        default:
            return "ERROR_TITLE"
        }
    }
}

struct SubredditInfoSection {
    
    let type: SubredditInfoSectionType
    let subTypes: [SubredditInfoRowType]
    
}

class SubredditInfoViewController: BeamTableViewController, SubredditTabItemViewController {
    
    lazy var privacyOverlaySwitch: UISwitch = { UISwitch() }()
    lazy var spoilerOverlaySwitch: UISwitch = { UISwitch() }()
    lazy var privateSwitch: UISwitch = { UISwitch() }()
    
    var titleView = SubredditTitleView.titleViewWithSubreddit(nil)
    
    weak var subreddit: Subreddit? {
        didSet {
            self.updateNavigationItem()
            self.createSections()
        }
    }
    
    fileprivate var sections: [SubredditInfoSection]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    lazy var multiredditSubreddits: [Subreddit] = {
        if let multireddit = self.subreddit as? Multireddit {
            return multireddit.subreddits?.sortedArray(using: [NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "identifier", ascending: true)]) as! [Subreddit]
        } else {
            return [Subreddit]()
        }
    }()
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateNavigationItem()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.privacyOverlaySwitch.addTarget(self, action: #selector(SubredditInfoViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
        self.spoilerOverlaySwitch.addTarget(self, action: #selector(SubredditInfoViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
        self.privateSwitch.addTarget(self, action: #selector(SubredditInfoViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditInfoViewController.objectContextObjectsDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: AppDelegate.shared.managedObjectContext)
        self.tableView.reloadData()
        
        self.updateSwitchStates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: AppDelegate.shared.managedObjectContext)
    }
    
    // MARK: - Sections
    
    func createSections() {
        var sections = [SubredditInfoSection]()
        
        if let characters = self.subreddit?.descriptionText, characters.count > 0 {
            sections.append(SubredditInfoSection(type: SubredditInfoSectionType.description, subTypes: [SubredditInfoRowType.description]))
        }
        
        if let multireddit = self.subreddit as? Multireddit {
            //Add the manage subreddits and "edit" actions only if the user can edit the multireddit
            if multireddit.canEdit == true && AppDelegate.shared.authenticationController.isAuthenticated {
                sections.append(SubredditInfoSection(type: SubredditInfoSectionType.multireddit, subTypes: [SubredditInfoRowType.manageSubreddits, SubredditInfoRowType.edit]))
            }
            
            //Add share only if the multireddit is public, in case it's private show the "OpenInSafari" button instead
            if multireddit.visibility.publiclyVisible {
                sections.append(SubredditInfoSection(type: SubredditInfoSectionType.actions, subTypes: [SubredditInfoRowType.share]))
            } else {
                sections.append(SubredditInfoSection(type: SubredditInfoSectionType.actions, subTypes: [SubredditInfoRowType.openInSafari]))
            }
            
            sections.append(SubredditInfoSection(type: SubredditInfoSectionType.options, subTypes: [SubredditInfoRowType.displayOptions, SubredditInfoRowType.contentFiltering]))
            
            if AppDelegate.shared.authenticationController.userCanViewNSFWContent {
                //Show the privacy option only if the user can see the "privacy" content
                sections.append(SubredditInfoSection(type: SubredditInfoSectionType.settings, subTypes: [SubredditInfoRowType.spoilerOverlay, SubredditInfoRowType.privacyOverlay]))
            } else {
                sections.append(SubredditInfoSection(type: SubredditInfoSectionType.settings, subTypes: [SubredditInfoRowType.spoilerOverlay]))
            }
            
            //Add privacy switch and delete button when the user can edit the multireddit
            if multireddit.canEdit == true && AppDelegate.shared.authenticationController.isAuthenticated {
                sections.append(SubredditInfoSection(type: SubredditInfoSectionType.destruction, subTypes: [SubredditInfoRowType.private, SubredditInfoRowType.delete]))
            }
        
        } else if let subreddit = self.subreddit {
            
            if self.subreddit?.isPrepopulated == false {
                var subredditActions = [SubredditInfoRowType]()
                if subreddit.isSubscriber ?? false == false {
                    subredditActions.append(SubredditInfoRowType.subscribe)
                } else if subreddit.isSubscriber == true && AppDelegate.shared.authenticationController.isAuthenticated {
                     subredditActions.append(SubredditInfoRowType.unsubscribe)
                }
                subredditActions.append(contentsOf: [SubredditInfoRowType.favorite, SubredditInfoRowType.addToMultireddit])
            
                //Add share only if the subreddit is public, in case it's private show the "OpenInSafari" button instead
                if subreddit.visibility.publiclyVisible {
                     subredditActions.append(SubredditInfoRowType.share)
                } else {
                    subredditActions.append(SubredditInfoRowType.openInSafari)
                }
                sections.append(SubredditInfoSection(type: SubredditInfoSectionType.actions, subTypes: subredditActions))
            }
            
            sections.append(SubredditInfoSection(type: SubredditInfoSectionType.options, subTypes: [SubredditInfoRowType.displayOptions, SubredditInfoRowType.contentFiltering]))
            
            if AppDelegate.shared.authenticationController.userCanViewNSFWContent {
                //Show the privacy option only if the user can see the "privacy" content
                sections.append(SubredditInfoSection(type: SubredditInfoSectionType.settings, subTypes: [SubredditInfoRowType.spoilerOverlay, SubredditInfoRowType.privacyOverlay]))
            } else {
                sections.append(SubredditInfoSection(type: SubredditInfoSectionType.settings, subTypes: [SubredditInfoRowType.spoilerOverlay]))
            }
            
        }
        self.sections = sections
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let section = self.sections?[section] {
            return section.subTypes.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let section = self.sections?[section] {
            return section.type.title
        }
        return nil
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        //This is to work around a bug where the background does not update
        let backgroundColor = tableView.backgroundColor
        view.backgroundColor = backgroundColor
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = backgroundColor
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = self.sections?[(indexPath as IndexPath).section] else {
            return self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SubredditInfoCell
        }
        let rowType = section.subTypes[(indexPath as IndexPath).row]
        if rowType == SubredditInfoRowType.description {
            let cell = tableView.dequeueReusableCell(withIdentifier: "description", for: indexPath) as! SubredditInfoDescriptionCell
            cell.accessoryView = nil
            cell.subreddit = self.subreddit
            cell.contentLabel.delegate = self
            cell.selectionStyle = .none
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SubredditInfoCell
            cell.rowType = rowType
            cell.accessoryType = rowType.accessoryType
            cell.accessoryView = nil
            cell.textLabel?.alpha = 1
            
            if let subreddit = self.subreddit {
                cell.textLabel?.text = rowType.titleForSubreddit(subreddit)
                cell.imageView?.image = rowType.iconForSubreddit(subreddit)
            } else {
                cell.textLabel?.text = nil
                cell.imageView?.image = nil
            }

            if rowType == SubredditInfoRowType.manageSubreddits {
                let badgeView = BadgeView(frame: CGRect(x: 0, y: 0, width: 28, height: 22))
                let subredditCount = (self.subreddit as? Multireddit)?.subreddits?.count ?? 0
                badgeView.text = "\(subredditCount)"
                cell.accessoryView = badgeView
            }
            if rowType == SubredditInfoRowType.privacyOverlay {
                cell.accessoryView = self.privacyOverlaySwitch
            }
            if rowType == SubredditInfoRowType.spoilerOverlay {
                cell.accessoryView = self.spoilerOverlaySwitch
            }
            if rowType == SubredditInfoRowType.private {
                cell.accessoryView = self.privateSwitch
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = self.sections?[(indexPath as IndexPath).section] else {
            return
        }
        let subType = section.subTypes[(indexPath as IndexPath).row]
        
        switch subType {
        case SubredditInfoRowType.edit:
            self.subredditTabBarController?.showEditMultireddit()
        case SubredditInfoRowType.manageSubreddits:
            self.subredditTabBarController?.showManageSubreddits()
        case SubredditInfoRowType.subscribe:
            self.subscribe()
        case SubredditInfoRowType.unsubscribe:
            self.confirmUnsubscribe(at: indexPath)
        case SubredditInfoRowType.favorite:
            if self.subreddit?.isBookmarked == true {
                self.removeFromFavorites()
            } else {
                self.addToFavorites()
            }
        case SubredditInfoRowType.displayOptions:
            self.performSegue(withIdentifier: "showDisplayOptions", sender: self)
        case SubredditInfoRowType.contentFiltering:
            self.performSegue(withIdentifier: "showContentFiltering", sender: self)
        case SubredditInfoRowType.addToMultireddit:
            self.subredditTabBarController?.showAddToMultireddit()
        case SubredditInfoRowType.delete:
            self.destruct(at: indexPath)
        case SubredditInfoRowType.share:
            self.share(at: indexPath)
        case SubredditInfoRowType.openInSafari:
            if let subredditPermalink = self.subreddit?.permalink {
                let urlString = "https://\((AppDelegate.shared.authenticationController.configuration.regularHost as NSString).appendingPathComponent(subredditPermalink))"
                UIApplication.shared.open(URL(string: urlString as String)!, options: [:], completionHandler: nil)
            }
        default:
            break
        }
    }

    // MARK: - Actions
    
    @objc fileprivate func objectContextObjectsDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            // This is a hack to prevent tableview offset changes for some reason.
            UIView.performWithoutAnimation { () -> Void in
                self.tableView.reloadData()
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }
    
    // MARK: - Switches
    
    func updateSwitchStates() {
        self.privacyOverlaySwitch.isOn = self.subreddit?.shouldShowNSFWOverlay() ?? true
        self.spoilerOverlaySwitch.isOn = self.subreddit?.shouldShowSpoilerOverlay() ?? true
        if let multireddit = self.subreddit as? Multireddit {
            self.privateSwitch.isOn = multireddit.visibility == SubredditVisibility.Private
        } else {
            self.privateSwitch.isOn = false
        }
    }
    
    @objc fileprivate func switchChanged(_ settingSwitch: UISwitch) {
        if settingSwitch == self.privacyOverlaySwitch {
            self.subreddit?.setShowNSFWOverlay(settingSwitch.isOn)
        } else if settingSwitch == self.spoilerOverlaySwitch {
            self.subreddit?.setShowSpoilerOverlay(settingSwitch.isOn)
        } else if settingSwitch == self.privateSwitch {
            guard self.subreddit is Multireddit else {
                return
            }
            let multireddit = self.subreddit as! Multireddit
            multireddit.visibility = privateSwitch.isOn ? SubredditVisibility.Private: SubredditVisibility.Public
            let updateOperation = multireddit.updateOperation(AppDelegate.shared.authenticationController)
            DataController.shared.executeAndSaveOperations([updateOperation], context: AppDelegate.shared.managedObjectContext) { (error: Error?) -> Void in
                
                DispatchQueue.main.async(execute: { () -> Void in
                    if let error = error {
                        let alertController = BeamAlertController(title: AWKLocalizedString("multireddit-change-visibility-failed"), message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addCancelAction()
                    }
                })
                
            }
        } else {
            AWKLog("Subreddit overlay/nsfw setting switch unimplemented", level: AWKLogLevel.warning)
        }
    }
    
    fileprivate func destruct(at indexPath: IndexPath) {
        if self.subreddit is Multireddit {
            self.delete(at: indexPath)
        } else if self.subreddit?.isSubscriber?.boolValue == true {
            self.unsubscribe()
        }
    }
    
    func subscribe() {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.Subscribe), animated: true, completion: nil)
            return
        }
        
        self.subreddit?.isSubscriber = true
        self.createSections()
        if let subscribeOperations = self.subreddit?.subscribeOperations(AppDelegate.shared.authenticationController) {
            DataController.shared.executeAndSaveOperations(subscribeOperations, context: AppDelegate.shared.managedObjectContext) { (error) -> Void in
                
                DispatchQueue.main.async(execute: { () -> Void in
                    Trekker.default.track(event: TrekkerEvent(event: "Subscribe Subreddit", properties: ["View": "Subreddit Info"]))
                    if let error = error as NSError? {
                        let name = self.subreddit?.displayName ?? AWKLocalizedString("subreddit")
                        let message = AWKLocalizedString("subscribe_subreddit_failure").replacingOccurrences(of: "[SUBREDDIT]", with: name).replacingOccurrences(of: "[ERROR]", with: error.localizedDescription)
                        self.presentErrorMessage(message as String)
                    } else {
                        self.createSections()
                    }
                })
            }
        } else {
            AWKDebugLog("Subreddit to subscribe is nil!")
        }
    }
    
    func confirmUnsubscribe(at indexPath: IndexPath) {
        let name = self.subreddit?.displayName ?? AWKLocalizedString("subreddit")
        let title = AWKLocalizedString("unsubscribe_subreddit_confirm").replacingOccurrences(of: "[SUBREDDIT]", with: name)
        let confirmSheet = BeamAlertController(title: title as String, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        confirmSheet.addAction(UIAlertAction(title: AWKLocalizedString("unsubscribe-button"), style: UIAlertActionStyle.destructive, handler: { (_) -> Void in
            self.unsubscribe()
        }))
        confirmSheet.addCancelAction()
        
        confirmSheet.popoverPresentationController?.sourceRect = self.tableView.rectForRow(at: indexPath)
        confirmSheet.popoverPresentationController?.sourceView = self.tableView
        
        self.present(confirmSheet, animated: true, completion: nil)
    }
    
    func unsubscribe() {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            self.present(UIAlertController.unauthenticatedAlertController(UnauthenticatedAlertType.Subscribe), animated: true, completion: nil)
            return
        }
        
        self.subreddit?.isSubscriber = false
        self.createSections()
        if let subscribeOperations = self.subreddit?.subscribeOperations(AppDelegate.shared.authenticationController, unsubscribe: true) {
            DataController.shared.executeAndSaveOperations(subscribeOperations, context: AppDelegate.shared.managedObjectContext) { (error) -> Void in
                
                DispatchQueue.main.async(execute: { () -> Void in
                    Trekker.default.track(event: TrekkerEvent(event: "Unsubscribe Subreddit", properties: ["View": "Subreddit Info"]))
                    if let error = error as NSError? {
                        let name = self.subreddit?.displayName ?? AWKLocalizedString("subreddit")
                        let message = AWKLocalizedString("unsubscribe_subreddit_failure").replacingOccurrences(of: "[SUBREDDIT]", with: name).replacingOccurrences(of: "[ERROR]", with: error.localizedDescription)
                        self.presentErrorMessage(message as String)
                    } else {
                        self.createSections()
                    }
                })
            }
        }
    }
    
    class func deleteMultireddit(_ multireddit: Multireddit) {
        guard AppDelegate.shared.authenticationController.isAuthenticated else {
            return
        }
        
        let operation = multireddit.deleteOperation(AppDelegate.shared.authenticationController)
        
        DataController.shared.executeAndSaveOperations([operation], context: AppDelegate.shared.managedObjectContext, handler: { (error: Error?) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if let error = error {
                    AWKDebugLog("Could not delete multireddit: \(error)")
                    let name = multireddit.displayName ?? AWKLocalizedString("multireddit")
                    let alertTitle = AWKLocalizedString("multireddit-delete-failure").replacingOccurrences(of: "[MULTIREDDIT]", with: name)
                    let alert = BeamAlertController(title: alertTitle as String, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addCancelAction()
                    alert.addAction(UIAlertAction(title: AWKLocalizedString("retry"), style: .default, handler: { (_) -> Void in
                        self.deleteMultireddit(multireddit)
                    }))
                    
                    AppDelegate.topViewController()?.present(alert, animated: true, completion: nil)
                }
            })
        })
        
    }
    
    fileprivate func delete(at indexPath: IndexPath) {
        
        if let multireddit = self.subreddit as? Multireddit {
            let name = multireddit.displayName ?? AWKLocalizedString("multireddit")
            let alertMessage = AWKLocalizedString("multireddit-delete-sure-message").replacingOccurrences(of: "[MULTIREDDIT]", with: name)
            let alert = BeamAlertController(title: nil, message: alertMessage as String, preferredStyle: UIAlertControllerStyle.actionSheet)
            alert.addCancelAction()
            alert.addAction(UIAlertAction(title: AWKLocalizedString("delete"), style: UIAlertActionStyle.destructive, handler: { (_) -> Void in
                SubredditInfoViewController.deleteMultireddit(multireddit)
                self.navigationController?.dismiss(animated: true, completion: nil)
            }))
            
            alert.popoverPresentationController?.sourceRect = self.tableView.rectForRow(at: indexPath)
            alert.popoverPresentationController?.sourceView = self.tableView
            
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    fileprivate func addToFavorites() {
        Trekker.default.track(event: TrekkerEvent(event: "Favorite subreddit", properties: ["View": "Subreddit info"]))
        
        self.subreddit?.changeBookmark(true)
        let saveOperations = DataController.shared.persistentSaveOperations(AppDelegate.shared.managedObjectContext)
        DataController.shared.executeOperations(saveOperations) { (error: Error?) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if let error = error {
                    AWKDebugLog("Could not bookmark subreddit: \(error)")
                } else {
                    AppDelegate.shared.updateFavoriteSubredditShortcuts()
                }
            })
        }
    }
    
    fileprivate func removeFromFavorites() {
        self.subreddit?.changeBookmark(false)
        let saveOperations = DataController.shared.persistentSaveOperations(AppDelegate.shared.managedObjectContext)
        DataController.shared.executeOperations(saveOperations) { (error: Error?) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if let error = error {
                    AWKDebugLog("Could not remove bookmark subreddit: \(error)")
                } else {
                    AppDelegate.shared.updateFavoriteSubredditShortcuts()
                }
            })
        }
    }
    
    func share(at indexPath: IndexPath) {
        guard let subreddit = self.subreddit else {
            return
        }
        let activityViewController = ShareActivityViewController(object: subreddit)
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> Void in
            if completed {
                Trekker.default.track(event: TrekkerEvent(event: "Share subreddit", properties: [
                    "Activity type": activityType?.rawValue ?? "Unknown",
                    "Private": NSNumber(value: true),
                    "Is Multireddit": subreddit is Multireddit,
                    "Used reddit link": NSNumber(value: true)
                    ]))
            }
            
        }
        
        activityViewController.popoverPresentationController?.sourceRect = self.tableView.rectForRow(at: indexPath)
        activityViewController.popoverPresentationController?.sourceView = self.tableView
        
        self.present(activityViewController, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let displayOptionsViewController = segue.destination as? SubredditDisplayOptionsViewController {
            displayOptionsViewController.subreddit = self.subreddit
        } else if let filteringViewController = segue.destination as? SubredditFilteringViewController {
            filteringViewController.subreddit = self.subreddit
        }
    }

}

// MARK: - TTTAttributedLabelDelegate
extension SubredditInfoViewController: TTTAttributedLabelDelegate {
    
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

extension SubredditInfoViewController: SubredditInfoDescriptionCellDelegate {
    
    func readMoreTappedForSubredditInfoDescriptionCell(_ cell: SubredditInfoDescriptionCell) {
        self.tableView.beginUpdates()
        cell.isExpanded = true
        self.tableView.endUpdates()
    }
    
}
