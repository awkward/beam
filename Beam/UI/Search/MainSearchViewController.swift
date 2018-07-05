//
//  MainSearchViewController.swift
//  beam
//
//  Created by Robin Speijer on 11-09-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData
import Trekker

enum MainSearchDisplayMode {
    case recentVisited
    case recentSearched
    case resultSuggestions
}

enum MainSearchTableViewSectionType {
    case searchedPosts
    case searchedSubreddits
}

private let MainSearchViewControllerHeaderHeight: CGFloat = 54.0
private let MainSearchViewControllerFooterHeight: CGFloat = 10.0

class MainSearchViewController: BeamTableViewController {
    
    let searchBar: UISearchBar = {
        let bar = UISearchBar(frame: CGRect())
        bar.searchBarStyle = UISearchBarStyle.default
        bar.placeholder = AWKLocalizedString("search-placeholder")
        bar.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        bar.autocapitalizationType = .none
        return bar
    }()
    
    var searchDisplayMode = MainSearchDisplayMode.recentVisited {
        didSet {
            let topOffset: CGFloat = self.searchDisplayMode == .resultSuggestions ? -1 * (MainSearchViewControllerHeaderHeight - 10) : 0
            self.tableView.contentInset = UIEdgeInsets(top: topOffset, left: 0, bottom: 0, right: 0)
            self.tableView.rowHeight = self.searchDisplayMode == .recentVisited ? 60: 44
            self.tableView.reloadData()
        }
    }
    
    var recentSearchSections: [MainSearchTableViewSectionType] {
        var sections = [MainSearchTableViewSectionType]()
        if RedditActivityController.recentlySearchedSubredditKeywords.count > 0 {
            sections.append(MainSearchTableViewSectionType.searchedSubreddits)
        }
        if RedditActivityController.recentlySearchedPostKeywords.count > 0 {
            sections.append(MainSearchTableViewSectionType.searchedPosts)
        }
        return sections
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ClearableTableSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "header")
        searchBar.delegate = self
        searchBar.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.navigationItem.titleView?.bounds.height ?? 44)
        navigationItem.titleView = self.searchBar
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MainSearchViewController.handleTapGesture(_:)))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(tapGestureRecognizer)
        
        self.registerForPreviewing(with: self, sourceView: self.tableView)
        
        if self.isModallyPresentedRootViewController() && self.tabBarController == nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_close"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MainSearchViewController.cancelTapped(_:)))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @objc fileprivate func cancelTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchPosts(_ keywords: String) {
        if let searchResultsViewController = self.storyboard?.instantiateViewController(withIdentifier: "postSearchResults") as? PostSearchResultsViewController {
            searchResultsViewController.title = keywords
            searchResultsViewController.searchKeywords = keywords
            
            RedditActivityController.addPostSearchKeywords(keywords)
            searchBar.endEditing(true)
            self.navigationController?.pushViewController(searchResultsViewController, animated: true)
        }
        
    }
    
    func searchSubreddits(_ keywords: String) {
        let subredditsStoryboard = UIStoryboard(name: "SubredditList", bundle: nil)
        let subredditListViewController = subredditsStoryboard.instantiateInitialViewController() as! SubredditListViewController
        
        let query = SubredditsCollectionQuery()
        query.searchKeywords = keywords
        query.shouldPrepopulate = false
        query.hideNSFWSubreddits = !AppDelegate.shared.authenticationController.userCanViewNSFWContent
        subredditListViewController.subredditQuery = query
        subredditListViewController.title = keywords
        
        RedditActivityController.addSubredditSearchKeywords(keywords)
        
        searchBar.endEditing(true)
        self.navigationController?.pushViewController(subredditListViewController, animated: true)
    }
    
    func openSubreddit(_ subreddit: Subreddit) {
        //Open the subreddit
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
            tabBarController.subreddit = subreddit
            self.present(tabBarController, animated: true, completion: nil)
        }
    }
    
    func openSubredditName(_ displayName: String) {
        SubredditQuery.fetchSubreddit(displayName) { (subreddit, error) -> Void in
            DispatchQueue.main.async(execute: {
                self.searchBar.endEditing(true)
                if let subreddit = subreddit {
                    self.openSubreddit(subreddit)
                } else {
                    if let error = error as NSError?, error.code == 403 {
                        self.presentErrorMessage(AWKLocalizedString("search_subreddit_private"))
                    } else {
                        self.presentErrorMessage(AWKLocalizedString("subreddit-not-found"))
                    }
                }
                
                if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedIndexPath, animated: true)
                }
            })
        }
        
    }
    
    func openUsername(_ username: String) {
        let navigationController = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as! BeamColorizedNavigationController
        let profileViewController = navigationController.viewControllers.first as! ProfileViewController
        profileViewController.username = username
        self.present(navigationController, animated: true, completion: nil)
    }
    
    fileprivate func clearTableSection(_ sectionType: MainSearchTableViewSectionType? = nil) {
        if searchDisplayMode == MainSearchDisplayMode.recentVisited {
            
            self.tableView.beginUpdates()
            let clearSubredditHistoryOperation = Subreddit.clearAllVisitedDatesOperation(AppDelegate.shared.managedObjectContext)
            DataController.shared.executeAndSaveOperations([clearSubredditHistoryOperation], context: AppDelegate.shared.managedObjectContext) { (_) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if self.tableView.numberOfSections > 0 {
                        self.tableView.deleteSections(NSIndexSet(index: 0) as IndexSet, with: .fade)
                    }
                    self.tableView.endUpdates()
                })
            }

        } else if let sectionType = sectionType, self.searchDisplayMode == MainSearchDisplayMode.recentSearched {
            self.tableView.beginUpdates()
            
            if let section = self.recentSearchSections.index(of: sectionType) {
                if self.tableView.numberOfSections > section {
                    self.tableView.deleteSections(IndexSet(integer: section), with: .fade)
                }
            }
            switch sectionType {
            case .searchedPosts:
                RedditActivityController.clearSearchedPostKeywords()
            case .searchedSubreddits:
                RedditActivityController.clearSearchedSubredditKeywords()
            }
            
            self.tableView.endUpdates()
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        switch displayMode {
        case .dark:
            searchBar.keyboardAppearance = .dark
        case .default:
            searchBar.keyboardAppearance = .default
        }
        searchBar.applyBeamNavigationBarStyle()
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            self.searchBar.endEditing(false)
        }
    }
    
}

// MARK: - UITableViewDataSource
extension MainSearchViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch searchDisplayMode {
        case .recentVisited:
            if RedditActivityController.recentlyVisitedSubreddits.count > 0 {
                return 1
            }
        case .recentSearched:
            return self.recentSearchSections.count
        case .resultSuggestions:
            return 1
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchDisplayMode {
        case .recentVisited:
            return RedditActivityController.recentlyVisitedSubreddits.count
        case .recentSearched:
            let sectionType = self.recentSearchSections[section]
            switch sectionType {
            case .searchedPosts:
                return RedditActivityController.recentlySearchedPostKeywords.count
            case .searchedSubreddits:
                return RedditActivityController.recentlySearchedSubredditKeywords.count
            }
        case .resultSuggestions:
            return 4
        }
    }
    
    func titleForHeaderInSection(_ section: Int) -> String? {
        switch searchDisplayMode {
        case .recentVisited:
            if RedditActivityController.recentlyVisitedSubreddits.count > 0 {
                return NSLocalizedString("recently-visited-subreddits", comment: "Recently visited subreddits")
            }
        case .recentSearched:
            let sectionType = self.recentSearchSections[section]
            switch sectionType {
            case .searchedSubreddits:
                return NSLocalizedString("recently-searched-subreddits", comment: "Recently searched subreddits")
            case .searchedPosts:
                 return NSLocalizedString("recently-searched-posts", comment: "Recently searched posts")
            }
        default:
            return nil
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SubredditListTableViewCell
        cell.subreddit = nil
        
        switch searchDisplayMode {
        case .recentVisited:
            let subreddit = RedditActivityController.recentlyVisitedSubreddits[indexPath.row]
            cell.subreddit = subreddit
        case .recentSearched:
            let sectionType = self.recentSearchSections[(indexPath as IndexPath).section]
            switch sectionType {
            case .searchedPosts:
                cell.textLabel?.text = RedditActivityController.recentlySearchedPostKeywords[(indexPath as IndexPath).row]
            case .searchedSubreddits:
                cell.textLabel?.text = RedditActivityController.recentlySearchedSubredditKeywords[(indexPath as IndexPath).row]
            }
        case .resultSuggestions:
            
            if (indexPath as IndexPath).row == 0 {
                cell.textLabel?.text = AWKLocalizedString("search-subreddits-with").replacingOccurrences(of: "[SEARCHTERM]", with: self.searchBar.text ?? "")
            } else if (indexPath as IndexPath).row == 1 {
                cell.textLabel?.text = AWKLocalizedString("search-posts-with").replacingOccurrences(of: "[SEARCHTERM]", with: self.searchBar.text ?? "")
            } else if (indexPath as IndexPath).row == 2 {
                cell.textLabel?.text = AWKLocalizedString("search-go-to-subreddit").replacingOccurrences(of: "[SUBREDDIT]", with: self.subredditNameFromSearchText(self.searchBar.text))
            } else if (indexPath as IndexPath).row == 3 {
                cell.textLabel?.text = AWKLocalizedString("search-go-to-user").replacingOccurrences(of: "[USERNAME]", with: self.subredditNameFromSearchText(self.searchBar.text))
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return MainSearchViewControllerHeaderHeight - 10
        default:
            return MainSearchViewControllerHeaderHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return MainSearchViewControllerFooterHeight
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let title = titleForHeaderInSection(section) {
            var sectionType: MainSearchTableViewSectionType?
            if self.searchDisplayMode == MainSearchDisplayMode.recentSearched {
                sectionType = self.recentSearchSections[section]
            }
            let headerView = ClearableTableSectionHeaderView(reuseIdentifier: "header")
            headerView.titleLabel.text = title.uppercased(with: Locale.current)
            headerView.clearButton.clearHandler = { [weak self] () -> Void in
                if let sectionType = sectionType, self?.searchDisplayMode == MainSearchDisplayMode.recentSearched {
                    self?.clearTableSection(sectionType)
                } else {
                    self?.clearTableSection()
                }
            }
            return headerView
        }
        return nil
    
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.searchDisplayMode == .recentVisited || self.searchDisplayMode == .recentSearched
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        
        //The number of rows in the section before deletion
        let oldNumberOfRows = tableView.numberOfRows(inSection: indexPath.section)
        //The new number of rows, can not be used with tableView.numberOfRows(inSection: indexPath.section)!
        var newNumberOfRows: Int? = nil
        
        if self.searchDisplayMode == .recentVisited {
            let shouldDeleteSection = tableView.numberOfRows(inSection: indexPath.section) <= 1
            RedditActivityController.recentlyVisitedSubreddits[indexPath.row].lastVisitDate = nil
            if shouldDeleteSection {
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
            } else {
                newNumberOfRows = RedditActivityController.recentlyVisitedSubreddits.count
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        } else if self.searchDisplayMode == .recentSearched {
            let sectionType = self.recentSearchSections[indexPath.section]
            switch sectionType {
            case .searchedSubreddits:
                let searchText = RedditActivityController.recentlySearchedSubredditKeywords[indexPath.row]
                RedditActivityController.removeSubredditSearchKeywords(searchText)
                if RedditActivityController.recentlySearchedSubredditKeywords.count == 0 {
                    tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
                } else {
                    newNumberOfRows = RedditActivityController.recentlySearchedSubredditKeywords.count
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            case .searchedPosts:
                let searchText = RedditActivityController.recentlySearchedPostKeywords[indexPath.row]
                RedditActivityController.removePostSearchKeywords(searchText)
                if RedditActivityController.recentlySearchedPostKeywords.count == 0 {
                    tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
                } else {
                    newNumberOfRows = RedditActivityController.recentlySearchedPostKeywords.count
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
        }
        
        //Insert a new row if the oldNumberOfRows is lower or the same as the new number of rows. And if no section was removed
        
        if let newNumberOfRows = newNumberOfRows, oldNumberOfRows <= newNumberOfRows {
            tableView.insertRows(at: [IndexPath(row: newNumberOfRows - 1, section: indexPath.section)], with: UITableViewRowAnimation.bottom)
        }
        
        tableView.endUpdates()
    }
    
    func subredditNameFromSearchText(_ searchText: String?) -> String {
        if searchText == nil {
            return ""
        }
        return searchText!.replacingOccurrences(of: " ", with: "_")
    }
    
    func usernameFromSearchText(_ searchText: String?) -> String {
        return self.subredditNameFromSearchText(searchText)
    }
    
}

// MARK: - UITableViewDelegate
extension MainSearchViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.searchDisplayMode == MainSearchDisplayMode.recentVisited {
            let subreddit = RedditActivityController.recentlyVisitedSubreddits[indexPath.row]
            self.openSubreddit(subreddit)
        } else if self.searchDisplayMode == MainSearchDisplayMode.recentSearched {
            let sectionType = self.recentSearchSections[(indexPath as IndexPath).section]
            switch sectionType {
            case .searchedSubreddits:
                let searchText = RedditActivityController.recentlySearchedSubredditKeywords[(indexPath as IndexPath).row]
                self.searchSubreddits(searchText)
            case .searchedPosts:
                let searchText = RedditActivityController.recentlySearchedPostKeywords[(indexPath as IndexPath).row]
                self.searchPosts(searchText)
            }
        } else if let searchText = self.searchBar.text, self.searchDisplayMode == MainSearchDisplayMode.resultSuggestions {
            if (indexPath as IndexPath).row == 0 {
                self.searchSubreddits(searchText)
            } else if (indexPath as IndexPath).row == 1 {
                self.searchPosts(searchText)
            } else if (indexPath as IndexPath).row == 2 {
                if AppDelegate.shared.cherryController.searchTermAllowed(term: searchText) == false {
                    self.presentErrorMessage(AWKLocalizedString("subreddit-blocked"))
                    tableView.deselectRow(at: indexPath, animated: true)
                } else {
                    self.openSubredditName(self.subredditNameFromSearchText(searchText))
                }
            } else if (indexPath as IndexPath).row == 3 {
                self.openUsername(self.usernameFromSearchText(searchText))
            }
        }
        self.searchBar.resignFirstResponder()
    }
    
}

// MARK: - UISearchBarDelegate
extension MainSearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchDisplayMode = searchBar.text?.count ?? 0 > 0 ? MainSearchDisplayMode.resultSuggestions: MainSearchDisplayMode.recentSearched
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        searchDisplayMode = searchBar.text?.count ?? 0 > 0 ? MainSearchDisplayMode.resultSuggestions: MainSearchDisplayMode.recentSearched
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            if searchText.contains(":") {
                self.searchPosts(searchText)
            } else {
                self.searchSubreddits(searchText)
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchDisplayMode = searchBar.text?.count == 0 ? MainSearchDisplayMode.recentVisited: MainSearchDisplayMode.resultSuggestions
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(false)
    }
    
}

extension MainSearchViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.searchDisplayMode != .recentVisited
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.tableView
    }
}

@available(iOS 9, *)
extension MainSearchViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location),
        let cell = self.tableView.cellForRow(at: indexPath) else {
            return nil
        }
        guard self.searchDisplayMode == MainSearchDisplayMode.recentVisited else {
            return nil
        }
        
        let subreddit = RedditActivityController.recentlyVisitedSubreddits[indexPath.row]
        //Open the subreddit
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
            tabBarController.subreddit = subreddit
            
            //Set the frame to animate the peek from
            previewingContext.sourceRect = cell.frame
            
            return tabBarController
        }

        return nil
    
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        //We only show subreddit view controller in this view, which is always presented modally
        self.present(viewControllerToCommit, animated: true, completion: nil)
    }
}
