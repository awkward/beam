//
//  MultiredditSubsViewController.swift
//  beam
//
//  Created by Robin Speijer on 07-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

let MultiredditSubCellIdentifier = "subreddit-edit"
let MultiredditMaxSubredditsCount = 50

class MultiredditSubsSearchController: UISearchController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return DisplayModeValue(UIStatusBarStyle.default, darkValue: UIStatusBarStyle.lightContent)
    }
}

class MultiredditSubsViewController: BeamTableViewController, NSFetchedResultsControllerDelegate, UISearchControllerDelegate, MultiredditSubsSearchViewControllerDelegate {
    
    var multireddit: Multireddit! {
        didSet {
            self.title = multireddit.displayName
            self.subreddits = multireddit.subreddits?.sortedArray(using: self.subredditSortDescriptors) as? [Subreddit]
        }
    }
    
    var subredditSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "displayName", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
    }
    
    var subreddits: [Subreddit]?
    var suggestions: [Subreddit]?
    
    fileprivate var collectionController = CollectionController(authentication: AppDelegate.shared.authenticationController, context: AppDelegate.shared.managedObjectContext)
    
    fileprivate var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let multiredditSubsSearch = MultiredditSubsSearchViewController(style: UITableViewStyle.plain)
        multiredditSubsSearch.multireddit = self.multireddit
        multiredditSubsSearch.delegate = self
        self.searchController = MultiredditSubsSearchController(searchResultsController: multiredditSubsSearch)
        self.searchController.searchResultsUpdater = self.searchController.searchResultsController as? SubredditsSearchViewController
        self.searchController.searchBar.scopeButtonTitles = [AWKLocalizedString("search-scope-subscribed"), AWKLocalizedString("search-scope-all")]
        self.searchController.searchBar.selectedScopeButtonIndex = 0
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.definesPresentationContext = true
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        self.tableView.register(UINib(nibName: "MultiredditSubTableViewCell", bundle: nil), forCellReuseIdentifier: "subreddit-edit")
        self.tableView.register(BeamPlainTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(MultiredditSubsViewController.doneButtonTapped(_:)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(MultiredditSubsViewController.userDidUpdate(_:)), name: AuthenticationController.UserDidChangeNotificationName, object: AppDelegate.shared.authenticationController)
        NotificationCenter.default.addObserver(self, selector: #selector(MultiredditSubsViewController.userDidUpdate(_:)), name: AuthenticationController.UserDidUpdateNotificationName, object: AppDelegate.shared.authenticationController)
        
        configureData()
        
        self.registerForPreviewing(with: self, sourceView: self.tableView)
    }
    
    @objc fileprivate func userDidUpdate(_ notification: Notification?) {
        DispatchQueue.main.async { () -> Void in
            self.configureData()
        }
    }
    
    fileprivate func configureData() {
        let subredditsQuery = SubredditsCollectionQuery()
        subredditsQuery.userIdentifier = AppDelegate.shared.authenticationController.activeUserIdentifier
        
        self.collectionController.query = subredditsQuery
        self.collectionController.startInitialFetching { (collectionID, _) -> Void in
            self.updateSuggestions(collectionID)
        }
        self.updateSuggestions(self.collectionController.collectionID)
    }
    
    fileprivate func updateSuggestions(_ collectionID: NSManagedObjectID?) {
        DispatchQueue.main.async { () -> Void in
            self.suggestions = self.filteredSuggestions(collectionID)
            self.tableView.reloadData()
        }
    }
    
    fileprivate func filteredSuggestions(_ collectionID: NSManagedObjectID?) -> [Subreddit]? {
        let context: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
        if let collectionID = collectionID, let collection = context.object(with: collectionID) as? SubredditCollection, let objects = collection.objects?.array as? [Subreddit] {
            return objects.filter({ (subreddit) -> Bool in
                guard let existingSubreddits = self.subreddits else {
                    return false
                }
                return subreddit.isPrepopulated && existingSubreddits.contains(subreddit) == false
            }).sorted(by: { (subreddit1, subreddit2) -> Bool in
                guard let displayName1 = subreddit1.displayName, let displayName2 = subreddit2.displayName else {
                    return false
                }
                return displayName1 < displayName2
            })
        } else {
            return nil
        }
    }
    
    @objc fileprivate func doneButtonTapped(_ sender: AnyObject) {
        self.multireddit.subreddits = NSSet(array: self.subreddits ?? [Subreddit]())
        MultiredditSubsViewController.updateMultireddit(self.multireddit)
        self.dismissViewController(sender)
    }
    
    fileprivate func presentSubredditLimitAlert() {
        let alert = BeamAlertController(title: AWKLocalizedString("manage-subreddits-limit-error"), message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addCancelAction()
        AppDelegate.topViewController(self)?.present(alert, animated: true, completion: nil)
    }
    
    fileprivate class func updateMultireddit(_ multireddit: Multireddit) {
        if let context = multireddit.managedObjectContext {
            
            let operation = multireddit.updateOperation(AppDelegate.shared.authenticationController)
            UIApplication.startNetworkActivityIndicator(for: operation)
            DataController.shared.executeAndSaveOperations([operation], context: context, handler: { (error) -> Void in
                
                UIApplication.stopNetworkActivityIndicator(for: operation)
                
                if let error = error, operation.multireddit.managedObjectContext != nil {
                    DispatchQueue.main.async {
                        let name = operation.multireddit.displayName ?? AWKLocalizedString("multireddit")
                        let titleString = AWKLocalizedString("multireddit-update-failure").replacingOccurrences(of: "[MULTIREDDIT]", with: name)
                        let alert = BeamAlertController(title: titleString as String, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                        alert.addCancelAction()
                        alert.addAction(UIAlertAction(title: AWKLocalizedString("retry"), style: .default, handler: { (_) -> Void in
                            updateMultireddit(operation.multireddit)
                        }))
                        AppDelegate.topViewController()?.present(alert, animated: true, completion: nil)
                    }
                }
                
            })
        }
    }
    
    // MARK: - Display Mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.searchController.searchBar.applyBeamBarStyleWithoutBorder()

    }

    // MARK: - Data
    
    var hasSubredditsSection: Bool { return self.subreddits?.count ?? 0 > 0 }
    var hasSuggestionsSection: Bool { return self.suggestions?.count ?? 0 > 0 }
    
    fileprivate func subredditAtIndexPath(_ indexPath: IndexPath) -> Subreddit {
        if indexPath.section == 0 && self.hasSubredditsSection {
            return self.subreddits![indexPath.row]
        } else {
            return self.suggestions![indexPath.row]
        }
    }
    
    fileprivate func addSubreddit(_ subreddit: Subreddit) {
        
        guard let subreddits = self.subreddits, subreddits.count < MultiredditMaxSubredditsCount else {
            self.presentSubredditLimitAlert()
            return
        }
        
        self.tableView.beginUpdates()
        
        var newSubreddits = self.subreddits ?? [Subreddit]()
        newSubreddits.append(subreddit)
        newSubreddits = (newSubreddits as NSArray).sortedArray(using: self.subredditSortDescriptors) as! [Subreddit]
        
        let newIndexPath = IndexPath(row: newSubreddits.index(of: subreddit)!, section: 0)
        
        if let oldIndex = self.suggestions?.index(of: subreddit) {
            if self.suggestions?.count == 1 {
                self.tableView.deleteSections(IndexSet(integer: self.hasSubredditsSection ? 1: 0), with: .automatic)
                self.tableView.insertRows(at: [newIndexPath], with: .automatic)
            } else {
                let oldIndexPath = IndexPath(row: oldIndex, section: self.hasSubredditsSection ? 1: 0)
                
                if self.hasSubredditsSection {
                    self.tableView.moveRow(at: oldIndexPath, to: newIndexPath)
                } else {
                    self.tableView.deleteRows(at: [oldIndexPath], with: .automatic)
                    self.tableView.insertSections(IndexSet(integer: 0), with: .automatic)
                }
                
            }
            
            self.suggestions?.remove(at: oldIndex)
            self.subreddits = newSubreddits
        } else {
            if self.hasSubredditsSection {
                self.tableView.insertRows(at: [newIndexPath], with: .automatic)
            } else {
                self.tableView.insertSections(IndexSet(integer: 0), with: .automatic)
            }
            self.subreddits = newSubreddits
        }
        
        CATransaction.setCompletionBlock { () -> Void in
            self.tableView.reloadData()
        }
        
        self.tableView.endUpdates()
        
    }
    
    fileprivate func removeSubredditAtIndex(_ index: Int) {
        
        CATransaction.begin()
        
        self.tableView.beginUpdates()
        let subreddit = self.subreddits![index]
        self.subreddits?.remove(at: index)
        let newSuggestions = self.filteredSuggestions(self.collectionController.collectionID)
        
        if let destinationIndex = newSuggestions?.index(of: subreddit), self.hasSubredditsSection && self.hasSuggestionsSection {
            
            let indexPath = IndexPath(row: index, section: 0)
            let newIndexPath = IndexPath(row: destinationIndex, section: 1)
            
            self.tableView.moveRow(at: indexPath, to: newIndexPath)
        } else {
            
            if !self.hasSubredditsSection {
                self.tableView.deleteSections(IndexSet(integer: 0), with: .automatic)
            } else {
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
            
            let destinationIndex = newSuggestions?.index(of: subreddit)
            if let destinationIndex = destinationIndex, self.hasSuggestionsSection {
                self.tableView.insertRows(at: [IndexPath(row: destinationIndex, section: 0)], with: .automatic)
            } else if destinationIndex != nil {
                self.tableView.insertSections(IndexSet(integer: 1), with: .automatic)
            }
        }
        
        CATransaction.setCompletionBlock { () -> Void in
            self.tableView.reloadData()
        }
        
        self.suggestions = newSuggestions
        
        self.tableView.endUpdates()
        
        CATransaction.commit()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (self.hasSubredditsSection ? 1: 0) + (self.hasSuggestionsSection ? 1: 0)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.hasSubredditsSection && section == 0 {
            return self.subreddits?.count ?? 0
        } else {
            return self.suggestions?.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MultiredditSubCellIdentifier, for: indexPath) as! MultiredditSubTableViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: MultiredditSubTableViewCell, atIndexPath indexPath: IndexPath) {

        var subreddit: Subreddit?
        cell.indexPath = indexPath
        
        if self.hasSubredditsSection && (indexPath as IndexPath).section == 0 {
            subreddit = self.subreddits?[indexPath.row]
            cell.editButton.setImage(UIImage(named: "delete_control"), for: UIControlState())
            cell.editButtonTappedHandler = { [weak self] () -> Void in
                self?.removeSubredditAtIndex((indexPath as IndexPath).row)
            }
        } else {
            subreddit = self.suggestions?[indexPath.row]
            cell.editButton.setImage(UIImage(named: "subscribe"), for: UIControlState())
            cell.editButtonTappedHandler = { [weak self] () -> Void in
                if let subreddit = subreddit {
                    self?.addSubreddit(subreddit)
                }
            }
        }
        
        cell.titleLabel?.text = subreddit?.displayName
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as! BeamPlainTableViewHeaderFooterView
        header.titleFont = UIFont.systemFont(ofSize: 11)
        return header
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.hasSubredditsSection && self.hasSuggestionsSection {
            switch section {
            case 0:
                return AWKLocalizedString("subreddits-in-multireddit").uppercased(with: Locale.current)
            case 1:
                return AWKLocalizedString("my-subreddits-title").uppercased(with: Locale.current)
            default:
                return nil
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var subreddit: Subreddit?
        if self.hasSubredditsSection && (indexPath as IndexPath).section == 0 {
            subreddit = self.subreddits?[indexPath.row]
        } else {
            subreddit = self.suggestions?[indexPath.row]
        }
        
        //Open the subreddit
        let storyboard = UIStoryboard(name: "Subreddit", bundle: nil)
        if let tabBarController = storyboard.instantiateInitialViewController() as? SubredditTabBarController {
            tabBarController.subreddit = subreddit
            self.present(tabBarController, animated: true, completion: nil)
        }
    }
    
    func searchViewController(_ viewController: SubredditsSearchViewController, commitEditingStyle editingStyle: UITableViewCellEditingStyle, subreddit: Subreddit) {
        
        if editingStyle == .delete {
            if let index = self.subreddits?.index(of: subreddit) {
                self.removeSubredditAtIndex(index)
            }
        } else if editingStyle == UITableViewCellEditingStyle.insert {
            self.addSubreddit(subreddit)
        }
    }
    
    func currentAddedSubredditsForSearchViewController(_ viewController: SubredditsSearchViewController) -> [Subreddit]? {
        return self.subreddits
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /**
        I'm not proud of this trick but it is needed to fix #2132. The view we are trying to find is very strange.
        This view is added by th UISearchBar, but is very hard to find
        First we have to look if the view is actually in the view, because sometimes when it's not in the view it's not on the view stack.
        Second we have to loop through all the views and get the RGB color value of that view. The view will be gray, meaning it has a red color value between 0.92 and 0.94.
        We have to do this everytime because sometimes the view is removed and created again or changes color
        */
        
        if self.tableView.contentOffset.y < -60 && self.displayMode == DisplayMode.dark {
            for view in self.tableView.subviews {
                var redColor: CGFloat = 0
                view.backgroundColor?.getRed(&redColor, green: nil, blue: nil, alpha: nil)
                if redColor > 0.921 && redColor < 0.94 {
                    view.backgroundColor = self.tableView.backgroundColor
                    break
                }
            }
        }
    }
    
}

extension MultiredditSubsViewController: BeamModalPresentation {

    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return BeamModalPresentationStyle.formsheet
    }
}

@available(iOS 9, *)
extension MultiredditSubsViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //Cell selection
        guard let indexPath = self.tableView.indexPathForRow(at: location), let cell = self.tableView.cellForRow(at: indexPath) else {
            return nil
        }
        
        var subreddit: Subreddit?
        if self.hasSubredditsSection && (indexPath as IndexPath).section == 0 {
            subreddit = self.subreddits?[indexPath.row]
        } else {
            subreddit = self.suggestions?[indexPath.row]
        }
        
        guard subreddit != nil else {
            return nil
        }
        
        //Make the subreddit previewing view controller
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
