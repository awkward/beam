//
//  SubredditFilteringViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 30-08-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

private enum SubredditFilteringType {
    case keywords
    case subreddits
}

class SubredditFilteringViewController: BeamViewController {

    var subreddit: Subreddit!
    
    @IBOutlet fileprivate var tableView: UITableView!
    @IBOutlet fileprivate var toolbar: UIToolbar!
    @IBOutlet fileprivate var buttonBarItem: UIBarButtonItem!
    @IBOutlet fileprivate var buttonBar: ButtonBar!
    
    fileprivate var keywordsChanged: Bool = false
    
    fileprivate var canFilterSubreddits: Bool {
        return self.subreddit.identifier == Subreddit.allIdentifier || self.subreddit.identifier == Subreddit.frontpageIdentifier
    }
    
    fileprivate var filteringType: SubredditFilteringType = SubredditFilteringType.keywords {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    fileprivate var filterKeywords: [String] {
        get {
            if let filterKeywords: [String] = self.subreddit?.filterKeywords, self.filteringType == SubredditFilteringType.keywords {
                return filterKeywords
            } else if let filterSubreddits: [String] = self.subreddit?.filterSubreddits, self.filteringType == SubredditFilteringType.subreddits {
                return filterSubreddits
            } else {
                return [String]()
            }
        }
        set {
            self.keywordsChanged = true
            if self.filteringType == SubredditFilteringType.keywords {
                self.subreddit.filterKeywords = newValue
            } else if self.filteringType == SubredditFilteringType.subreddits {
                self.subreddit.filterSubreddits = newValue
            }
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.title = NSLocalizedString("content-filtering-view-title", comment: "The title of the content filtering subreddit setting view")
        
        if self.canFilterSubreddits {
            self.buttonBar.items = [ButtonBarButton(title: NSLocalizedString("keywords-filtering-type", comment: "The button in the top bar of the subreddit filtering screen"), showsBadge: false),
                                                           ButtonBarButton(title: NSLocalizedString("subreddits-filtering-type", comment: "The button in the top bar of the subreddit filtering screen"), showsBadge: false)]
            self.toolbar.isHidden = false
            self.tableView.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        } else {
            self.toolbar.isHidden = true
            self.buttonBar.items = [ButtonBarButton(title: NSLocalizedString("keywords-filtering-type", comment: "The button in the top bar of the subreddit filtering screen"), showsBadge: false)]
        }
        
        self.buttonBar.addTarget(self, action: #selector(SubredditFilteringViewController.buttonBarChanged(_:)), for: UIControlEvents.valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SubredditFilteringViewController.keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.keywordsChanged == true {
            self.keywordsChanged = false
            let dataController: DataController = DataController.shared
            let operations: [Operation] = dataController.persistentSaveOperations(AppDelegate.shared.managedObjectContext)
            dataController.executeOperations(operations) { (error: Error?) in
                if let error = error {
                    print("Error saving filters \(error)")
                }
            }
        }
    }
    
    @objc fileprivate func buttonBarChanged(_ sender: ButtonBar) {
        if sender.selectedItemIndex == 1 && self.canFilterSubreddits {
            self.filteringType = SubredditFilteringType.subreddits
        } else {
            self.filteringType = SubredditFilteringType.keywords
        }
    }
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        switch self.displayMode {
        case .default:
            self.view.backgroundColor = UIColor.groupTableViewBackground
            self.tableView.backgroundColor = UIColor.groupTableViewBackground
            self.tableView.separatorColor = UIColor.beamTableViewSeperatorColor()
            self.tableView.sectionIndexBackgroundColor = UIColor.beamBarColor()
            self.tableView.sectionIndexColor = UIColor.beamColor()
        case .dark:
            self.view.backgroundColor = UIColor.beamDarkBackgroundColor()
            self.tableView.backgroundColor = UIColor.beamDarkBackgroundColor()
            self.tableView.separatorColor = UIColor.beamDarkTableViewSeperatorColor()
            self.tableView.sectionIndexBackgroundColor = UIColor.beamDarkContentBackgroundColor()
            self.tableView.sectionIndexColor = UIColor.beamPurpleLight()
        }
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    @objc fileprivate func keyboardWillChangeFrame(_ notification: Notification) {
        //We can only change the frame if we own the keyboard and the user info is available
        guard let userInfo = (notification as NSNotification).userInfo, let isLocalKeyboard = userInfo[UIKeyboardIsLocalUserInfoKey] as? NSNumber, isLocalKeyboard == true else {
            return
        }
        //We can only animate if the frame value is available
        guard let keyboardFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        //Cet the CGRect of the keyboard frame NSValue
        let keyboardFrame = keyboardFrameValue.cgRectValue
        //Get the keyboard animation duration
        let keyboardAnimationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0
        //Get the keyboard animation curve
        var keyboardAnimationOptions: UIViewAnimationOptions = UIViewAnimationOptions()
        if userInfo[UIKeyboardAnimationCurveUserInfoKey] != nil {
            (userInfo[UIKeyboardAnimationCurveUserInfoKey]! as AnyObject).getValue(&keyboardAnimationOptions)
        }
        
        //Calculate the height the keyboard is covering
        let keyboardHeight = self.view.bounds.maxY - keyboardFrame.minY
        
        var insets: UIEdgeInsets = self.tableView.contentInset
        insets.bottom = keyboardHeight
        
        var scrollBarInsets: UIEdgeInsets = self.tableView.scrollIndicatorInsets
        scrollBarInsets.bottom = keyboardHeight
        
        //Animate the doing the frame calculation of the view
        UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: keyboardAnimationOptions, animations: {
            self.tableView.contentInset = insets
            self.tableView.scrollIndicatorInsets = scrollBarInsets
            self.view.layoutIfNeeded()
            }, completion: nil)
        
    }
    
}

extension SubredditFilteringViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filterKeywords.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as IndexPath).row < self.filterKeywords.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "keyword", for: indexPath)
            
            let keyword: String = self.filterKeywords[(indexPath as IndexPath).row]
            cell.textLabel!.text = keyword
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            
            return cell
        } else {
            let cell: SubredditFilteringTextFieldTableViewCell = tableView.dequeueReusableCell(withIdentifier: "textfield", for: indexPath) as! SubredditFilteringTextFieldTableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            if self.filteringType == SubredditFilteringType.subreddits {
                cell.placeholder = NSLocalizedString("add-subreddit-placeholder", comment: "The placeholder in the textfield for content filtering")
            } else {
                cell.placeholder = NSLocalizedString("add-keyword-placeholder", comment: "The placeholder in the textfield for content filtering")
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == UITableViewCellEditingStyle.delete && (indexPath as IndexPath).row < self.filterKeywords.count else {
            return
        }
        let keyword: String = self.filterKeywords[(indexPath as IndexPath).row]
        var keywords: [String] = self.filterKeywords
        if let index: Int = keywords.index(of: keyword) {
            keywords.remove(at: index)
            self.filterKeywords = keywords
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard (indexPath as IndexPath).row < self.filterKeywords.count else {
            return false
        }
        return true
    }
}

extension SubredditFilteringViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let keyword: String = textField.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).lowercased() {
            var keywords = self.filterKeywords
            if keyword.count < 2 {
                if self.filteringType == SubredditFilteringType.subreddits {
                    let alertController: UIAlertController = UIAlertController(alertWithCloseButtonAndTitle: NSLocalizedString("filter-subreddit-too-short-alert-title", comment: "The title of the alert when the filter subreddit is too short"), message: NSLocalizedString("filter-subreddit-too-short-alert-message", comment: "The message of the alert when the filter subreddit is too short"))
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    let alertController: UIAlertController = UIAlertController(alertWithCloseButtonAndTitle: NSLocalizedString("filter-keyword-too-short-alert-title", comment: "The title of the alert when the filter keyword is too short"), message: NSLocalizedString("filter-keyword-too-short-alert-message", comment: "The message of the alert when the filter keyword is too short"))
                    self.present(alertController, animated: true, completion: nil)
                }
            } else if keywords.contains(keyword) {
                if self.filteringType == SubredditFilteringType.subreddits {
                    let alertController: UIAlertController = UIAlertController(alertWithCloseButtonAndTitle: NSLocalizedString("filter-subreddit-already-exists-alert-title", comment: "The title of the alert when the filter subreddit already exists"), message: NSLocalizedString("filter-subreddit-already-exists-alert-message", comment: "The message of the alert when the filter subreddit already exists"))
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    let alertController: UIAlertController = UIAlertController(alertWithCloseButtonAndTitle: NSLocalizedString("filter-keyword-already-exists-alert-title", comment: "The title of the alert when the filter keyword already exists"), message: NSLocalizedString("filter-keyword-already-exists-alert-message", comment: "The message of the alert when the filter keyword already exists"))
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                textField.text = ""
                keywords.append(keyword)
                self.filterKeywords = keywords
                self.tableView.insertRows(at: [IndexPath(row: self.filterKeywords.count - 1, section: 0)], with: UITableViewRowAnimation.automatic)
            }
        }
        return false
    }
}
