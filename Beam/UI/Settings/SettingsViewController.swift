//
//  SettingsViewController.swift
//  beam
//
//  Created by Robin Speijer on 29-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import SDWebImage
import MessageUI
import Trekker
import CoreSpotlight

let BeamAppStoreURL = URL(string: "https://itunes.apple.com/nl/app/beam-for-reddit/id937987469?l=en&mt=8")
let BeamAppStoreReviewURL = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=937987469&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software")

enum SettingsRowType {
    case `default`
    case action
    case destructive
}

enum SettingsRowKey: String {
    case PrivacyOverlay = "privacy-overlay"
    case SpoilerOverlay = "spoiler-overlay"
    case PostMarking = "post-marking"
    case Sounds = "sounds"
    case DisplayOptions = "display-options"
    case Notifications = "notifications"
    case Browser = "open-links-in"
    case DefaultLaunchScreen = "default-launch-screen"
    case ManageImgurUploads = "manage-imgur-uploads"
    
    case Passcode = "passcode"
    case PrivateBrowsing = "privacy-mode"
    
    case ClearCache = "clear-cache"
    case ClearSearchHistory = "clear-search"

    case AboutBeam = "about-beam"
    case Donate = "donate"
    case PrivacyPolicy = "privacy-policy"
    case Terms = "terms"
    case Feedback = "feedback-support"
    case RateApp = "rate-us"
    case TellFriends = "tell-friends"
    
    case AddAccount = "add-account"
    case Logout = "logout"
    case LogoutAll = "logout-all-accounts"
    
    var viewControllerIdentifier: String? {
        switch self {
        case .DisplayOptions:
            return "display-options"
        case .Notifications:
            return "notifications"
        case .Browser:
            return "browser"
        case .DefaultLaunchScreen:
            return "open-app-on"
        case .AboutBeam:
            return "about"
        case .Donate:
            return "donation"
        case .ManageImgurUploads:
            return "imgur-manager"
        default:
            return nil
        }
    }
    
    var requiresPasscode: Bool {
        switch self {
        case .Passcode, .ManageImgurUploads:
            return true
        default:
            return false
        }
    }
    
    var selectable: Bool {
        switch self {
        case .PrivacyOverlay, .SpoilerOverlay, .PostMarking, .Sounds, .PrivateBrowsing:
            return false
        default:
            return true
        }
    }
}

class SettingsRow: NSObject {
    let key: SettingsRowKey
    var accessoryView: UIView?
    var showsDisclosureIndicator = false
    var textColorType = BeamTableViewCellTextColorType.default
    var detailTitle: (() -> (String?))?
    
    var title: String {
        if self.key == SettingsRowKey.Logout {
            if let username = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username {
                return AWKLocalizedString("logout-account-setting-title").replacingOccurrences(of: "[USERNAME]", with: username)
            } else {
                return AWKLocalizedString("logout-setting-title")
            }
        }
        return AWKLocalizedString("\(self.key.rawValue)-setting-title")
    }
    
    var accessoryType: UITableViewCellAccessoryType {
        return self.showsDisclosureIndicator ? UITableViewCellAccessoryType.disclosureIndicator: UITableViewCellAccessoryType.none
    }
    
    init(key: SettingsRowKey) {
        self.key = key
    }
    
    init(key: SettingsRowKey, colorType: BeamTableViewCellTextColorType) {
        self.key = key
        self.textColorType = colorType
    }
    
    init(key: SettingsRowKey, accessoryView: UIView) {
        self.key = key
        self.accessoryView = accessoryView
    }
    
    init(key: SettingsRowKey, disclosureIndicator: Bool) {
        self.key = key
        self.showsDisclosureIndicator = disclosureIndicator
    }
    
}

struct SettingsSection {
    var headerTitle: String?
    var footerTitle: String?
    let rows: [SettingsRow]
    
    init(title: String, rows: [SettingsRow]) {
        self.headerTitle = title
        self.rows = rows
    }
    
    init(rows: [SettingsRow]) {
        self.rows = rows
    }
    
    init(headerTitle: String?, footerTitle: String?, rows: [SettingsRow]) {
        self.headerTitle = headerTitle
        self.footerTitle = footerTitle
        self.rows = rows
    }
}

class SettingsViewController: BeamTableViewController {
    
    let privacyOverlaySwitch = UISwitch()
    let spoilerOverlaySwitch = UISwitch()
    let postMarkingSwitch = UISwitch()
    let playSoundsSwitch = UISwitch()
    let privateBrowsingSwitch = UISwitch()
    
    var sections: [SettingsSection]!

    var selectedRow: SettingsRow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reloadSections()
        self.tableView.reloadData()
        
        self.navigationItem.title = AWKLocalizedString("settings-title")
        
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsViewController.userDidChange(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsViewController.userDidChange(_:)), name: AuthenticationController.UserDidUpdateNotificationName, object: nil)

        self.setupCells()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateSwitchStatuses()
        self.updateCellDetails()
        self.reloadSections()
        self.tableView.reloadData()
        if self.presentedViewController == nil {
            Trekker.default.track(event: TrekkerEvent(event: "View settings"))
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    @objc fileprivate func userDidChange(_ notification: Notification) {
        DispatchQueue.main.async { () -> Void in
            self.reloadSections()
            self.updateSwitchStatuses()
            self.updateCellDetails()
            self.tableView.reloadData()
        }
    }
    
    fileprivate func reloadSections() {
        var sections = [SettingsSection]()
        
        //General
        if let rows = self.rowsForGeneralSection() {
            sections.append(SettingsSection(title: AWKLocalizedString("settings-settings-header"), rows: rows))
        }
       
        //Privacy
        if let rows = self.rowsForPrivacySection() {
            sections.append(SettingsSection(title: AWKLocalizedString("privacy-settings-header"), rows: rows))
        }
        
        //History
        if let rows = self.rowsForHistorySection() {
            sections.append(SettingsSection(title: AWKLocalizedString("history-settings-header"), rows: rows))
        }
        
        //About
        if let rows = self.rowsForAboutSection() {
            let appRelease = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
            let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
            sections.append(SettingsSection(headerTitle: AWKLocalizedString("about-settings-header"), footerTitle: "v\(appVersion) (\(appRelease))", rows: rows))
        }
        
        //Accounts
        if let rows = self.rowsForAccountsSection() {
            sections.append(SettingsSection(headerTitle: nil, footerTitle: nil, rows: rows))
        }
        
        self.sections = sections
    }
    
    fileprivate func rowsForGeneralSection() -> [SettingsRow]? {
        var rows = [SettingsRow]()
        
        //rows.append(SettingsRow(key: .NSFWContent, accessoryView: self.NSFWContentSwitch))
        rows.append(SettingsRow(key: .SpoilerOverlay, accessoryView: self.spoilerOverlaySwitch))
        if AppDelegate.shared.authenticationController.userCanViewNSFWContent {
            rows.append(SettingsRow(key: .PrivacyOverlay, accessoryView: self.privacyOverlaySwitch))
        }
        rows.append(SettingsRow(key: .PostMarking, accessoryView: self.postMarkingSwitch))
        rows.append(SettingsRow(key: .Sounds, accessoryView: self.playSoundsSwitch))
        rows.append(SettingsRow(key: .DisplayOptions, disclosureIndicator: true))
        rows.append(SettingsRow(key: .Notifications, disclosureIndicator: true))
        
        let browserRow = SettingsRow(key: .Browser, disclosureIndicator: true)
        browserRow.detailTitle = {
            return UserSettings[.browser].displayName
        }
        rows.append(browserRow)
        
        let launchScreenRow = SettingsRow(key: .DefaultLaunchScreen, disclosureIndicator: true)
        launchScreenRow.detailTitle = {
            return UserSettings[.appOpen].title
        }
        rows.append(launchScreenRow)
        
        rows.append(SettingsRow(key: .ManageImgurUploads, disclosureIndicator: true))
        
        guard rows.count > 0 else {
            return nil
        }
        return rows
    }
   
    fileprivate func rowsForPrivacySection() -> [SettingsRow]? {
        var rows = [SettingsRow]()
        
        let passcodeRow = SettingsRow(key: .Passcode, disclosureIndicator: true)
        passcodeRow.detailTitle = {
            return AppDelegate.shared.passcodeController.passcodeEnabled ? AWKLocalizedString("passcode-enabled") : AWKLocalizedString("passcode-disabled")
        }
        rows.append(passcodeRow)
        rows.append(SettingsRow(key: .PrivateBrowsing, accessoryView: self.privateBrowsingSwitch))
        
        guard rows.count > 0 else {
            return nil
        }
        return rows
    }
    
    fileprivate func rowsForHistorySection() -> [SettingsRow]? {
        var rows = [SettingsRow]()
        
        rows.append(SettingsRow(key: .ClearCache, colorType: .followAppTintColor))
        rows.append(SettingsRow(key: .ClearSearchHistory, colorType: UserSettings[.privacyModeEnabled] ? .disabled :  .followAppTintColor))
        
        guard rows.count > 0 else {
            return nil
        }
        return rows
    }
    
    fileprivate func rowsForAboutSection() -> [SettingsRow]? {
        var rows = [SettingsRow]()
        
        rows.append(SettingsRow(key: .AboutBeam, disclosureIndicator: true))
        rows.append(SettingsRow(key: .Donate, disclosureIndicator: true))
        rows.append(SettingsRow(key: .PrivacyPolicy, disclosureIndicator: true))
        rows.append(SettingsRow(key: .Terms, disclosureIndicator: true))
        rows.append(SettingsRow(key: .Feedback, disclosureIndicator: true))
        rows.append(SettingsRow(key: .RateApp, disclosureIndicator: true))
        rows.append(SettingsRow(key: .TellFriends, disclosureIndicator: true))
        
        guard rows.count > 0 else {
            return nil
        }
        return rows
    }
    
    fileprivate func rowsForAccountsSection() -> [SettingsRow]? {
        var rows = [SettingsRow]()
        
        let accounts = AppDelegate.shared.authenticationController.fetchAllAuthenticationSessions()
        guard accounts.count > 0 else {
            return nil
        }
        rows.append(SettingsRow(key: .AddAccount, colorType: .default))
        if AppDelegate.shared.authenticationController.activeUserSession != nil {
            rows.append(SettingsRow(key: .Logout, colorType: .destructive))
        }
        if accounts.count > 1 {
            rows.append(SettingsRow(key: .LogoutAll, colorType: .destructive))
        }
        
        guard rows.count > 0 else {
            return nil
        }
        return rows
    }
    
    func setupCells() {
        //NSFW Overlay
        self.privacyOverlaySwitch.addTarget(self, action: #selector(SettingsViewController.switchChanged(_:)), for: .valueChanged)
        
        //Spoiler Overlay
        self.spoilerOverlaySwitch.addTarget(self, action: #selector(SettingsViewController.switchChanged(_:)), for: .valueChanged)
        
        //Play Sounds
        self.playSoundsSwitch.addTarget(self, action: #selector(SettingsViewController.switchChanged(_:)), for: .valueChanged)
        
        //Privacy mode
        self.privateBrowsingSwitch.addTarget(self, action: #selector(SettingsViewController.switchChanged(_:)), for: .valueChanged)
        
        //Post marking
        self.postMarkingSwitch.addTarget(self, action: #selector(SettingsViewController.switchChanged(_:)), for: .valueChanged)
        
        self.updateSwitchStatuses()
    }
    
    func updateSwitchStatuses() {
        //NSFW Overlay
        self.privacyOverlaySwitch.isOn = UserSettings[.showPrivacyOverlay]
        
        //Spoiler Overlay
        self.spoilerOverlaySwitch.isOn = UserSettings[.showSpoilerOverlay]
        
        //Play Sounds
        self.playSoundsSwitch.isOn = UserSettings[.playSounds]
        
        //Private browsing
        self.privateBrowsingSwitch.isOn = UserSettings[.privacyModeEnabled]
        
        //Post marking
        self.postMarkingSwitch.isOn = UserSettings[.postMarking]
    }
    
    func updateCellDetails() {
        self.privacyOverlaySwitch.isEnabled = AppDelegate.shared.authenticationController.userCanViewNSFWContent == true
        
        self.privateBrowsingSwitch.isEnabled = true
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = self.sections[section]
        return section.rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settings-cell", for: indexPath) as! SettingsTableViewCell
        
        let section = self.sections[(indexPath as IndexPath).section]
        let row = section.rows[(indexPath as IndexPath).row]
        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.detailTitle?()
        cell.accessoryView = row.accessoryView
        cell.accessoryType = row.accessoryType
        cell.textColorType = row.textColorType
        cell.selectionStyle = row.key.selectable ? UITableViewCellSelectionStyle.default: UITableViewCellSelectionStyle.none
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = self.sections[(indexPath as IndexPath).section]
        let row = section.rows[(indexPath as IndexPath).row]
        
        self.selectedRow = row
        
        let key = row.key
        
        if key.requiresPasscode == true && AppDelegate.shared.passcodeController.passcodeEnabled == true {
            let storyboard = UIStoryboard(name: "Passcode", bundle: nil)
            if let navigationController = storyboard.instantiateViewController(withIdentifier: "enter-passcode") as? UINavigationController, let passcodeViewController = navigationController.topViewController as? EnterPasscodeViewController {
                passcodeViewController.delegate = self
                passcodeViewController.action = PasscodeAction.check
                self.showDetailViewController(navigationController, sender: nil)
            }
        } else {
            self.performAction(at: indexPath)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = self.sections[section]
        return section.headerTitle
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let section = self.sections[section]
        return section.footerTitle
    }
    
    // MARK: - Actions
    
    fileprivate func performAction(at indexPath: IndexPath) {
        guard let selectedRow = self.selectedRow else {
            return
        }
        if let identifier = selectedRow.key.viewControllerIdentifier {
            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: identifier) {
                self.show(viewController, sender: selectedRow)
            }
        } else {
            switch selectedRow.key {
            case .ClearCache:
                self.clearCaches()
            case .ClearSearchHistory:
                if !UserSettings[.privacyModeEnabled] {
                    self.clearSearchHistory({
                        let alertController = BeamAlertController(title: AWKLocalizedString("search-history-cleared-title"), message: AWKLocalizedString("search-history-cleared-message"), preferredStyle: .alert)
                        alertController.addCloseAction()
                        self.present(alertController, animated: true, completion: nil)
                    })
                }
            case .PrivacyPolicy:
                self.openWebsiteWithURL(URL(string: "http://beamreddit.com/privacy-policy-app.html")!)
            case .Terms:
                self.openWebsiteWithURL(URL(string: "http://beamreddit.com/terms-of-service-app.html")!)
            case .Feedback:
                self.presentSupportMailComposerViewController()
            case .RateApp:
                guard let url = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(Config.appleAppID)&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software") else {
                    return
                }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            case .TellFriends:
                let activityViewController = UIActivityViewController(activityItems: [AWKLocalizedString("app-store-share-message"), BeamAppStoreURL!], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.tableView
                activityViewController.popoverPresentationController?.sourceRect = self.tableView.cellForRow(at: indexPath)?.frame ?? CGRect()
                self.present(activityViewController, animated: true, completion: nil)
            case .AddAccount:
                self.addAccountTapped()
            case .Logout:
                self.logout()
            case .LogoutAll:
                self.logoutAll()
            case .Passcode:
                self.showPasscodeOptionsView()
            default:
                break
            }
        }
    }
    
    // MARK: - Passcode
    
    fileprivate func showPasscodeOptions() {
        if AppDelegate.shared.passcodeController.passcodeEnabled == true {
            let storyboard = UIStoryboard(name: "Passcode", bundle: nil)
            if let navigationController = storyboard.instantiateViewController(withIdentifier: "enter-passcode") as? UINavigationController, let passcodeViewController = navigationController.topViewController as? EnterPasscodeViewController {
                passcodeViewController.delegate = self
                passcodeViewController.action = PasscodeAction.check
                self.showDetailViewController(navigationController, sender: nil)
            }
        } else {
            self.showPasscodeOptionsView()
        }
    }
    
    fileprivate func showPasscodeOptionsView() {
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "passcode") as? PasscodeOptionsViewController {
            self.show(viewController, sender: nil)
        }
    }
    
    // MARK: - Clear methods
    
    fileprivate func clearCaches() {
        SDImageCache.shared().clearDisk()
        SDImageCache.shared().clearMemory()
        let operation = DataController.clearAllObjectsOperation(AppDelegate.shared.managedObjectContext)
        DataController.shared.executeOperations([operation], handler: nil)
        let alertController = BeamAlertController(title: AWKLocalizedString("cache-cleared-title"), message: AWKLocalizedString("cache-cleared-message"), preferredStyle: .alert)
        alertController.addCloseAction()
        self.present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func clearSearchHistory(_ completionHandler: (() -> Void)? = nil) {
        RedditActivityController.clearSearchedPostKeywords()
        RedditActivityController.clearSearchedSubredditKeywords()
        CSSearchableIndex.default().deleteAllSearchableItems { (_) in
            NSLog("Core spotlight search results cleared")
        }
        
        let clearSubredditHistoryOperation = Subreddit.clearAllVisitedDatesOperation(AppDelegate.shared.managedObjectContext)
        DataController.shared.executeAndSaveOperations([clearSubredditHistoryOperation], context: AppDelegate.shared.managedObjectContext) { (_) -> Void in
            
            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler?()
            })
            
        }
        
    }
    
    func addAccountTapped() {
        if AppDelegate.shared.authenticationController.fetchAllAuthenticationSessions().count > 0 && !UserSettings[.hasBeenShownTheAddAccountWarning] {
            UserSettings[.hasBeenShownTheAddAccountWarning] = true
            let alertController = BeamAlertController(title: AWKLocalizedString("add-additional-account-warning-title"), message: AWKLocalizedString("add-additional-account-warning-message"), preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: AWKLocalizedString("login-button"), style: UIAlertActionStyle.cancel, handler: { (_) in
                 AppDelegate.shared.presentAuthenticationViewController()
            }))
            self.present(alertController, animated: true, completion: nil)
        } else {
            AppDelegate.shared.presentAuthenticationViewController()
        }
        
    }
    
    func openWebsiteWithURL(_ URL: Foundation.URL) {
        let webViewController = WebViewController(nibName: "WebViewController", bundle: nil)
        webViewController.initialUrl = URL
        self.navigationController?.pushViewController(webViewController, animated: true)
    }
    
    func logout() {
        let alertController = BeamAlertController(title: AWKLocalizedString("logout-sure-title"), message: AWKLocalizedString("logout-sure-message"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("logout-sure-button"), style: .destructive, handler: { (_) -> Void in
            if let session = AppDelegate.shared.authenticationController.activeUserSession {
                AppDelegate.shared.authenticationController.removeUserSession(session, handler: { [weak self] () -> Void in
                    DispatchQueue.main.async {
                        self?.reloadSections()
                        self?.tableView.reloadData()
                    }
                })
            }
        }))
        alertController.addCancelAction()
        self.present(alertController, animated: true, completion: nil)
    }
    
    func logoutAll() {
        let alertController = BeamAlertController(title: AWKLocalizedString("logout-all-sure-title"), message: AWKLocalizedString("logout-all-sure-message"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: AWKLocalizedString("logout-sure-button"), style: .destructive, handler: { (_) -> Void in
            AppDelegate.shared.authenticationController.removeAllUserAccounts()
            DispatchQueue.main.async {
                self.reloadSections()
                self.tableView.reloadData()
            }
        }))
        alertController.addCancelAction()
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentSupportMailComposerViewController() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.setSubject(AWKLocalizedString("support-mail-subject"))
            mailComposeViewController.setToRecipients(["support@beamreddit.com"])
            mailComposeViewController.mailComposeDelegate = self
            mailComposeViewController.setMessageBody(self.supportEmailBody(), isHTML: false)
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            let title = AWKLocalizedString("feedback-not-possible")
            let message = AWKLocalizedString("feedback-not-possible-message")
            let alertController = BeamAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addCloseAction()
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func supportEmailBody() -> String {
        let appRelease = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        
        var string = "\n\nSome information to help us with the problem:\n\n"
        string += "App Information:\n"
        string += "Installed App Version: \(appVersion) (\(appRelease)\n"
        string += "\n"
        string += "Device Information:\n"
        string += "Device Model: \(UIDevice.current.deviceModel)\n"
        string += "iOS Version: \(UIDevice.current.systemVersion)\n"
        string += "Locale: \(Locale.current.identifier)\n"
        
        return string
    }
    
    // MARK: - Actions
    
    @IBAction func closeButtonTapped(_ sender: AnyObject) {
        self.dismissViewController(sender)
    }
    
    @objc func switchChanged(_ sender: UISwitch?) {
        if let sender = sender {
            var key: SettingsKey<Bool>?
            if sender == self.privacyOverlaySwitch {
                key = .showPrivacyOverlay
                UserSettings[.subredditsPrivacyOverlaySetting] = nil
            } else if sender == self.spoilerOverlaySwitch {
                key = .showSpoilerOverlay
                UserSettings[.subredditsSpoilerOverlaySetting] = nil
            } else if sender == self.playSoundsSwitch {
                key = .playSounds
            } else if sender == self.postMarkingSwitch {
                key = .postMarking
            } else if sender == self.privateBrowsingSwitch {
                key = .privacyModeEnabled
                if sender.isOn == false {
                    UserSettings[.privateBrowserWarningShown] = false
                } else if sender.isOn == true {
                    AppDelegate.shared.updateAnalyticsUser()
                    self.clearSearchHistory()
                }
            } else {
                assert(false, "Unimplemented switch change")
            }
            if let key = key {
                UserSettings[key] = sender.isOn
            }
            if let key = key, key == SettingsKeys.privacyModeEnabled {
                self.reloadSections()
                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 2)], with: UITableViewRowAnimation.fade)
                if sender.isOn == false {
                    AppDelegate.shared.updateAnalyticsUser()
                }
            }
            self.updateCellDetails()
            
        }
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}

extension SettingsViewController: BeamModalPresentation {
    
    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return BeamModalPresentationStyle.formsheet
    }
}

extension SettingsViewController: EnterPasscodeViewControllerDelegate {
    
    func passcodeViewControllerDidCancel(_ viewController: EnterPasscodeViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func passcodeViewController(_ viewController: EnterPasscodeViewController, didCreateNewPasscode passcode: String) {
        //Not used
    }
    
    func passcodeViewController(_ viewController: EnterPasscodeViewController, didEnterPasscode passcode: String) -> Bool {
        if AppDelegate.shared.passcodeController.passcodeIsCorrect(passcode) {
            viewController.dismiss(animated: true, completion: nil)
            self.performAction(at: IndexPath(row: 0, section: 0))
            return true
        }
        return false
    }
    
    func passcodeViewControllerDidAuthenticateWithTouchID(_ viewController: EnterPasscodeViewController) {
        //Not used
    }
    
}
