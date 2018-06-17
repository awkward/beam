//
//  MultiredditSubsSearchViewController.swift
//  beam
//
//  Created by Robin Speijer on 10-07-15.
//  Copyright © 2015 Awkward. All rights reserved.
//

import UIKit
import Snoo

protocol MultiredditSubsSearchViewControllerDelegate: SubredditsSearchViewControllerDelegate {
    
    func searchViewController(_ viewController: SubredditsSearchViewController, commitEditingStyle editingStyle: UITableViewCellEditingStyle, subreddit: Subreddit)
    func currentAddedSubredditsForSearchViewController(_ viewController: SubredditsSearchViewController) -> [Subreddit]?
    
}

class MultiredditSubsSearchViewController: SubredditsSearchViewController {

    weak var multireddit: Multireddit?
    var addedSubreddits: [Subreddit]?

    override init(style: UITableViewStyle) {
        super.init(style: style)
        
        self.tableView.register(UINib(nibName: "MultiredditSubTableViewCell", bundle: nil), forCellReuseIdentifier: "subreddit-edit")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.tableView.register(UINib(nibName: "MultiredditSubTableViewCell", bundle: nil), forCellReuseIdentifier: "subreddit-edit")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "subreddit-edit", for: indexPath) as! MultiredditSubTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
        
    }
    
    fileprivate func configureCell(_ cell: MultiredditSubTableViewCell, atIndexPath indexPath: IndexPath) {
        
        let subreddit = self.objects?[indexPath.row]
        cell.indexPath = indexPath
        cell.selectionStyle = .default
        
        let editingStyle = self.editingStyleAtIndexPath(indexPath)
        if editingStyle == .delete {
            cell.editButton.setImage(UIImage(named: "delete_control"), for: UIControlState())
            cell.editButtonTappedHandler = { [weak self] () -> Void in
                self?.commitSubredditAtIndexPath(indexPath)
            }
        } else {
            cell.editButton.setImage(UIImage(named: "subscribe"), for: UIControlState())
            cell.editButtonTappedHandler = { [weak self] () -> Void in
                self?.commitSubredditAtIndexPath(indexPath)
            }
        }
        
        cell.titleLabel?.text = subreddit?.displayName
    }

    fileprivate func editingStyleAtIndexPath(_ indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if let addedSubreddits = self.addedSubreddits, let subreddit = self.objects?[indexPath.row] {
            return addedSubreddits.index(of: subreddit) != nil ? UITableViewCellEditingStyle.delete: UITableViewCellEditingStyle.insert
        }
        
        return UITableViewCellEditingStyle.none
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.commitSubredditAtIndexPath(indexPath)
    }
    
    func commitSubredditAtIndexPath(_ indexPath: IndexPath) {
        if self.delegate is MultiredditSubsSearchViewControllerDelegate {
            if let subreddit = self.objects?[indexPath.row] {
                let editingStyle = self.editingStyleAtIndexPath(indexPath)
                (self.delegate as! MultiredditSubsSearchViewControllerDelegate).searchViewController(self, commitEditingStyle: editingStyle, subreddit: subreddit)
                
            }
            self.addedSubreddits = (self.delegate as! MultiredditSubsSearchViewControllerDelegate).currentAddedSubredditsForSearchViewController(self)
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addedSubreddits = (self.delegate as! MultiredditSubsSearchViewControllerDelegate).currentAddedSubredditsForSearchViewController(self)
        self.tableView.reloadData()
    }

}
