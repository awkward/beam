//
//  EditMultiredditViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 05-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import CoreData

final class EditMultiredditViewController: BeamTableViewController {
    
    var multireddit: Multireddit? {
        didSet {
            if self.nameTextField != nil {
                self.configureContents()
            }
        }
    }
    
    var copyingMultireddit: Bool = false {
        didSet {
            if self.nameTextField != nil {
                self.configureContents()
                self.reloadSaveBarButtonItem()
            }
        }
    }

    @IBOutlet fileprivate var nameTextField: UITextField!
    @IBOutlet fileprivate var descriptionTextView: UITextView!
    @IBOutlet fileprivate var descriptionTextViewPlaceholder: UILabel!
    @IBOutlet fileprivate var privateTableCell: UITableViewCell!
    
    lazy fileprivate var allowedCharacters: CharacterSet = {
        let characterSet = NSMutableCharacterSet(charactersIn: "_0123456789")
        characterSet.formUnion(with: CharacterSet.uppercaseLetters)
        characterSet.formUnion(with: CharacterSet.lowercaseLetters)
        return characterSet as CharacterSet
    }()
    
    fileprivate var savePossible: Bool {
        return self.nameTextField.text!.count > 0
    }
    fileprivate var loading: Bool = false {
        didSet {
            self.reloadSaveBarButtonItem()
            
            self.nameTextField.isEnabled = !self.loading
            self.descriptionTextView.isEditable = !self.loading
            self.privateSwitch.isEnabled = !self.loading
        }
    }
    
    lazy var privateSwitch = UISwitch()
    
    fileprivate var creatingMultireddit: Bool {
        return self.multireddit == nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelection = false
        
        self.nameTextField.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(EditMultiredditViewController.nameFieldValueChanged(_:)), name: NSNotification.Name.UITextFieldTextDidChange, object: self.nameTextField)
        
        self.descriptionTextView.textContainerInset = UIEdgeInsets()
        self.descriptionTextView.textContainer.lineFragmentPadding = 0
        self.descriptionTextView.delegate = self
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(EditMultiredditViewController.cancel(_:)))
        
        if self.copyingMultireddit {
            self.title = AWKLocalizedString("create-copy")
        } else if self.creatingMultireddit {
            self.title = AWKLocalizedString("create-multireddit")
        } else {
            self.title = AWKLocalizedString("edit-multireddit")
        }
        
        self.nameTextField.placeholder = AWKLocalizedString("name-placeholder")
        self.descriptionTextViewPlaceholder.text = AWKLocalizedString("description-placeholder")
        self.privateTableCell.textLabel?.text = AWKLocalizedString("private-label")
        
        self.reloadSaveBarButtonItem()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.configureContents()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View
    
    fileprivate func configureContents() {
        self.nameTextField.text = self.multireddit?.displayName
        self.descriptionTextView.text = self.multireddit?.descriptionText
        if let multireddit = self.multireddit {
            self.privateSwitch.isOn = multireddit.visibility == SubredditVisibility.Private
        } else {
            self.privateSwitch.isOn = true
        }
        self.descriptionTextViewPlaceholder.isHidden = (self.descriptionTextView.text as NSString).length > 0
        self.reloadSaveBarButtonItem()
    }
    
    fileprivate func reloadSaveBarButtonItem() {
        if self.loading {
            let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            loadingIndicator.startAnimating()
            let loadingButtonItem = UIBarButtonItem(customView: loadingIndicator)
            self.navigationItem.rightBarButtonItem = loadingButtonItem
            return
        } else if self.copyingMultireddit {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: AWKLocalizedString("copy-button"), style: UIBarButtonItemStyle.done, target: self, action: #selector(EditMultiredditViewController.save(_:)))
        } else if self.creatingMultireddit {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: AWKLocalizedString("create"), style: UIBarButtonItemStyle.done, target: self, action: #selector(EditMultiredditViewController.save(_:)))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: AWKLocalizedString("save"), style: UIBarButtonItemStyle.done, target: self, action: #selector(EditMultiredditViewController.save(_:)))
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = self.savePossible
    }
    
    // MARK: - Actions
    
    @objc fileprivate func cancel(_ sender: AnyObject?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func save(_ sender: AnyObject?) {
        guard let name = self.nameTextField.text, name.rangeOfCharacter(from: self.allowedCharacters.inverted) == nil && name.count > 3 else {
            let alertController = BeamAlertController(title: AWKLocalizedString("create-multireddit-characters"), message: AWKLocalizedString("create-multireddit-characters-message"), preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: AWKLocalizedString("OK"), style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        BeamSoundType.tap.play()
        self.loading = true
        
        let multireddit = self.multireddit
        var newMultireddit: Multireddit?
        if self.creatingMultireddit || self.copyingMultireddit {
            newMultireddit = NSEntityDescription.insertNewObject(forEntityName: Multireddit.entityName(), into: AppDelegate.shared.managedObjectContext) as? Multireddit
        }
        
        if let multireddit = multireddit {
            if self.copyingMultireddit {
                self.copyMultireddit(multireddit, newMultireddit: newMultireddit!)
            } else {
                self.updateMultireddit(multireddit)
            }
        } else if let newMultireddit = newMultireddit {
            if self.creatingMultireddit {
                self.createMultireddit(newMultireddit)
            }
        }
        
    }
    
    fileprivate func copyMultireddit(_ multireddit: Multireddit, newMultireddit: Multireddit) {
        if let fromPermalink = multireddit.permalink {
            newMultireddit.author = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username
            newMultireddit.visibility = SubredditVisibility.Private
            newMultireddit.displayName = self.nameTextField.text
            
            if let username = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username, let title = self.nameTextField.text, let escapedTitle = URL.stringByAddingUrlPercentagesToString(title)?.replacingOccurrences(of: "%20", with: "+") {
                newMultireddit.permalink = "/user/\(username)/m/\(escapedTitle)"
            }
            
            //Copy should be performed on a new multireddit, otherwise the old multireddit will become incorrect
            let copyOperation = newMultireddit.copyOperation(fromPermalink, authenticationController: AppDelegate.shared.authenticationController)
            
            self.executeMultiredditOperations([copyOperation])
        }
        
    }
    
    fileprivate func updateMultireddit(_ multireddit: Multireddit) {
        let hasBeenRenamed = self.multireddit?.displayName != self.nameTextField.text
        
        multireddit.displayName = self.nameTextField.text
        multireddit.descriptionText = self.descriptionTextView.text
        multireddit.descriptionTextMarkdownString = nil
        
        var operations = [Operation]()
        let updateOperation = multireddit.updateOperation(AppDelegate.shared.authenticationController)
        if hasBeenRenamed {
            let renameOperation = multireddit.renameOperation(AppDelegate.shared.authenticationController)
            operations.append(renameOperation)
            updateOperation.addDependency(renameOperation)
        }
        operations.append(updateOperation)
        
        self.executeMultiredditOperations(operations)
    }
    
    fileprivate func createMultireddit(_ multireddit: Multireddit) {
        multireddit.author = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username
        multireddit.visibility = self.privateSwitch.isOn ? SubredditVisibility.Private: SubredditVisibility.Public
        multireddit.displayName = self.nameTextField.text
        multireddit.descriptionText = self.descriptionTextView.text
        
        if let username = AppDelegate.shared.authenticationController.activeUser(AppDelegate.shared.managedObjectContext)?.username, let title = self.nameTextField.text, let escapedTitle = URL.stringByAddingUrlPercentagesToString(title)?.replacingOccurrences(of: "%20", with: "+") {
            multireddit.permalink = "/user/\(username)/m/\(escapedTitle)"
        }
        
        let createOperation = multireddit.createOperation(AppDelegate.shared.authenticationController)
        
        self.executeMultiredditOperations([createOperation])
    }

    fileprivate func executeMultiredditOperations(_ operations: [Operation]) {
        DataController.shared.executeAndSaveOperations(operations, context: AppDelegate.shared.managedObjectContext, handler: { [weak self] (error: Error?) -> Void in
            
            DispatchQueue.main.async(execute: { () -> Void in
                if let error = error {
                    var message = error.localizedDescription
                    if error.localizedDescription == "conflict" {
                        message = AWKLocalizedString("multireddit-already-exists")
                    }
                    let alertController = BeamAlertController(title: AWKLocalizedString("create-multireddit-failure"), message: message, preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: AWKLocalizedString("OK"), style: .cancel, handler: nil))
                    self?.present(alertController, animated: true, completion: nil)
                } else {
                    if self?.copyingMultireddit == true {
                        //When copying, go back to the subreddits list
                        AppDelegate.shared.window?.rootViewController?.dismiss(animated: true, completion: nil)
                    } else {
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
                
                self?.loading = false
            })
        })
    }
    
    // MARK: - Display Mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.descriptionTextView?.textColor = DisplayModeValue(UIColor.beamGreyExtraDark(), darkValue: UIColor(red: 217 / 255.0, green: 217 / 255.0, blue: 217 / 255.0, alpha: 1))
        self.nameTextField?.textColor = DisplayModeValue(UIColor.beamGreyExtraDark(), darkValue: UIColor(red: 217 / 255.0, green: 217 / 255.0, blue: 217 / 255.0, alpha: 1))
        self.descriptionTextViewPlaceholder?.textColor = DisplayModeValue(UIColor.beamGreyExtraDark(), darkValue: UIColor(red: 217 / 255.0, green: 217 / 255.0, blue: 217 / 255.0, alpha: 1)).withAlphaComponent(0.4)
        self.nameTextField.attributedPlaceholder = self.attributedPlaceholderText(self.nameTextField)
    }
    
    fileprivate func attributedPlaceholderText(_ textField: UITextField?) -> NSAttributedString? {
        if let textField = textField {
            var placeholderString = textField.placeholder
            if placeholderString == nil {
                placeholderString = textField.attributedPlaceholder?.string
            }
            if placeholderString != nil {
                let textColor = textField.textColor?.withAlphaComponent(0.4)
                return NSAttributedString(string: placeholderString!, attributes: [NSAttributedStringKey.foregroundColor: textColor!])
            }
        }
        return nil
    }
    
    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.copyingMultireddit {
            return 1
        } else if self.creatingMultireddit {
            return 3
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as IndexPath).row == 1 {
            return UITableViewAutomaticDimension
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.4
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 && self.copyingMultireddit {
            return AWKLocalizedString("copy-multireddit-message")
        }
        return nil
    }
    
    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath as IndexPath).row == 2 {
            cell.accessoryView = self.privateSwitch
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if (indexPath as IndexPath).row == 0 {
            self.nameTextField.becomeFirstResponder()
        } else if (indexPath as IndexPath).row == 1 {
            self.descriptionTextView.becomeFirstResponder()
        }
    }
    
}

extension EditMultiredditViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        self.descriptionTextViewPlaceholder.isHidden = (self.descriptionTextView.text as NSString).length > 0
        self.reloadSaveBarButtonItem()
    }
}

extension EditMultiredditViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.descriptionTextView.becomeFirstResponder()
        return false
    }
    
    @objc func nameFieldValueChanged(_ notification: Notification) {
        self.reloadSaveBarButtonItem()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //The string is not allowed to be longer than 21 characters, so if it's longer don't allow to replace the string. BUT if the string is not longer than zero it means it's removing. So that replacement is allowed
        if let text = textField.text, textField == self.nameTextField && text.count >= 21 && string.count > 0 {
            return false
        }
        //If the string contains invalid characters it's not allowed to be replaced. In swift the range is nil if the characters are not found.
        if textField == self.nameTextField && string.rangeOfCharacter(from: self.allowedCharacters.inverted) != nil {
            return false
        }
        return true
    }
    
}

extension EditMultiredditViewController: BeamModalPresentation {

    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return BeamModalPresentationStyle.formsheet
    }
}
