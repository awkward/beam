//
//  CreatePostViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 23-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import SDWebImage
import CoreData

class CreatePostViewController: BeamViewController {

    // MARK: Properties to override
    
    /// Use this property to set the subreddit to post the link or text post to
    var subreddit: Subreddit? {
        didSet {
            self.updateSubmitStatus()
        }
    }
    
    var resubmit = false
    var sendReplies = true
    
    /// Override this property to tell the view if you can post or not
    internal var canSubmit: Bool {
        return self.subreddit != nil
    }
    
    /// Override this property to tell the view if it has contents
    internal var hasContent: Bool {
        return false
    }
    
    /// Override this property supply the kind of the post
    internal var postKind: RedditSubmitKind {
        fatalError("Override this property")
    }
    
    /// Override this property to supply the title of the post
    internal var postTitle: String {
        fatalError("Override this property")
    }
    
    /// Call this method when "canSubmit" has changed
    internal func updateSubmitStatus() {
        if self.post != nil {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: AWKLocalizedString("update-button"), style: UIBarButtonItemStyle.done, target: self, action: #selector(CreatePostViewController.submitTapped(_:)))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: AWKLocalizedString("post-button"), style: UIBarButtonItemStyle.done, target: self, action: #selector(CreatePostViewController.submitTapped(_:)))
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = self.canSubmit && self.isPosting == false
    }
    
    /// Set the post to allow edits
    var post: Post? {
        didSet {
            self.subreddit = self.post?.subreddit
            self.updateSubmitStatus()
            self.updatePrefilled()
        }
    }
    
    internal var isPosting: Bool {
        return self.posting
    }
    
    fileprivate var posting: Bool = false
    
    // MARK: Mehods to override
    
    /// Called when the submit starts
    internal func didStartSubmit() {
        
    }
    
    /**
     Called when a post is set, this can be used to update prefilled fields
     */
    internal func updatePrefilled() {
    
    }
    
    /// Called when an error occurs or the submit is finished
    internal func didFinishSubmit(_ error: Error?, cancelled: Bool) {
        if error != nil || cancelled == true {
            self.lockView(false)
            if let error = error {
                self.handleError(error)
            }
        } else {
            self.dismiss(animated: true, completion: {
                if let noticeHandler = AppDelegate.topViewController() as? NoticeHandling {
                    noticeHandler.presentSuccessMessage(AWKLocalizedString("post-successfully-submitted"))
                }
            })
        }
    }
    
    internal func handleError(_ error: Error) {
        DispatchQueue.main.async {
           
            let alertController = BeamAlertController(alertWithCloseButtonAndTitle: AWKLocalizedString("submit-error-title"), message: error.localizedDescription)
            let nsError = error as NSError
            if nsError.domain == BeamErrorDomain {
                switch nsError.code {
                case -401:
                    alertController.title = AWKLocalizedString("invalid-title-error-title")
                    alertController.message = AWKLocalizedString("invalid-title-error-message")
                case -402:
                    alertController.title = AWKLocalizedString("subreddit-missing-error-title")
                    alertController.message = AWKLocalizedString("subreddit-missing-error-message")
                default:
                    alertController.message = nsError.localizedDescription
                }
            } else if let redditError = nsError.redditErrorKey {
                switch redditError {
                case .BadCaptcha:
                    alertController.title = AWKLocalizedString("incorrect-captcha-error-title")
                    alertController.message = AWKLocalizedString("incorrect-captcha-error-message")
                    alertController.addAction(UIAlertAction(title: AWKLocalizedString("retry-button"), style: UIAlertActionStyle.default, handler: { (_) in
                        self.startSubmit()
                    }))
                case .AlreadySubmitted:
                    if self.resubmit == true {
                        alertController.title = AWKLocalizedString("already-submitted-not-possible-error-title")
                        alertController.message = AWKLocalizedString("already-submitted-not-possible-error-message")
                    } else {
                        alertController.title = AWKLocalizedString("already-submitted-error-title")
                        alertController.message = AWKLocalizedString("already-submitted-error-message")
                        alertController.addAction(UIAlertAction(title: AWKLocalizedString("resubmit-button"), style: UIAlertActionStyle.default, handler: { (_) in
                            self.resubmit = true
                            self.startSubmit()
                        }))
                    }
                case .RateLimited:
                    alertController.title = AWKLocalizedString("rate-limited-error-title")
                    alertController.message = AWKLocalizedString("rate-limited-error-message")
                case .SubredditDoesntExist:
                    alertController.title = AWKLocalizedString("subreddit-doesnt-exist-error-title")
                    alertController.message = AWKLocalizedString("subreddit-doesnt-exist-error-message")
                case .NoSelfTextAllowed:
                    alertController.title = AWKLocalizedString("text-not-allowed-error-title")
                    alertController.message = AWKLocalizedString("text-not-allowed-error-message")
                case .NoLinksAllowed:
                    alertController.title = AWKLocalizedString("links-not-allowed-error-title")
                    alertController.message = AWKLocalizedString("links-not-allowed-error-message")
                default:
                    AWKDebugLog("reddit error not translated: %@", redditError.rawValue)
                }
            }
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_close"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(CreatePostViewController.cancelTapped(_:)))
        
        self.updateSubmitStatus()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CreatePostViewController.internalTextFieldDidChange(_:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CreatePostViewController.internalKeyboardDidChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CreatePostViewController.internalKeyboardDidChangeFrame(_:)), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        
        if let navigationController = self.navigationController as? BeamNavigationController {
            navigationController.useInteractiveDismissal = false
        }
        
        if self.post != nil {
            self.updatePrefilled()
        }
    }
    
    // MARK: Actions
    
    @IBAction internal func cancelTapped(_ sender: AnyObject) {
        if self.hasContent {
            var title = AWKLocalizedString("discard-post-alert-title")
            var message = AWKLocalizedString("discard-post-alert-message")
            if self.post != nil {
                title = AWKLocalizedString("discard-edit-alert-title")
                message = AWKLocalizedString("discard-edit-alert-message")
            }
            let alertController = BeamAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: AWKLocalizedString("discard-button"), style: UIAlertActionStyle.destructive, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: AWKLocalizedString("keep-button"), style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction internal func submitTapped(_ sender: AnyObject) {
        self.startSubmit()
        
    }
    
    // MARK: Notifications
    
    @objc fileprivate func internalKeyboardDidChangeFrame(_ notification: Notification) {
        let frame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = ((notification as NSNotification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as? NSNumber ?? NSNumber(value: 0 as Double)).doubleValue
        var animationCurve: UIViewAnimationOptions = UIViewAnimationOptions()
        if (notification as NSNotification).userInfo?[UIKeyboardAnimationCurveUserInfoKey] != nil {
            ((notification as NSNotification).userInfo![UIKeyboardAnimationCurveUserInfoKey]! as AnyObject).getValue(&animationCurve)
        }
        let keyboardFrame = self.view.convert(frame, from: nil)
        //Forward the notification in an easier format to the subclasses of this class
        self.keyboardDidChangeFrame(keyboardFrame, animationDuration: animationDuration, animationCurveOption: animationCurve)
    }
    
    @objc fileprivate func internalTextFieldDidChange(_ notification: Notification) {
        self.updateSubmitStatus()
        if let textField = notification.object as? UITextField {
            self.textfieldDidChange(textField)
        }
    }
    
    // MARK: - Blocking user action while posting
    
    func lockView(_ locked: Bool) {
        self.navigationItem.leftBarButtonItem?.isEnabled = !locked
        self.navigationItem.rightBarButtonItem?.isEnabled = !locked
    }
    
    // MARK: Keyboard and textfield functions
    
    /// Called when the keyboard appears, disappears or changes frame
    ///
    /// - Parameters:
    ///   - frame: The frame of the keyboard in the UIScreen screenspace
    ///   - animationDuration: The duration of the keyboard animation
    ///   - animationCurveOption: The curve of the keyboard animation
    internal func keyboardDidChangeFrame(_ frame: CGRect, animationDuration: TimeInterval, animationCurveOption: UIViewAnimationOptions) {
        
    }
    
    /// Called when the text in a textfield changes
    ///
    /// - Parameter textField: The textfield of which the text changes
    internal func textfieldDidChange(_ textField: UITextField) {
        
    }
    
    // MARK: Display Mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        self.view.backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
    }
    
    // MARK: Post submitting
    
    fileprivate func startSubmit() {
        self.didStartSubmit()
        self.posting = true
        self.performSubmit()
    }
    
    fileprivate func performSubmit() {
        self.submitPost(self.postTitle, kind: self.postKind) { (error) in
            DispatchQueue.main.async(execute: {
                self.posting = false
                self.didFinishSubmit(error, cancelled: false)
            })
        }
    }
    
    fileprivate func submitPost(_ title: String, kind: RedditSubmitKind, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        guard title.trimmingCharacters(in: CharacterSet.whitespaces).count != 0 else {
            completionHandler(NSError.beamError(-401, localizedDescription: "Title missing"))
            return
        }
        guard self.subreddit != nil else {
            completionHandler(NSError.beamError(-402, localizedDescription: "Subreddit missing"))
            return
        }
        let authenticationController = AppDelegate.shared.authenticationController
        let dataController = DataController.shared
        let context: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
        do {
            if let post = self.post {
                var content: String?
                switch kind {
                case .text(let selfText):
                    content = selfText
                default:
                    break
                }
                guard let text = content else {
                    completionHandler(NSError.beamError(localizedDescription: "Unknown error"))
                    return
                }
                
                let operations = try post.updateOperations(text, authenticationcontroller: authenticationController)
                post.content = text
                post.markdownString = nil
                dataController.executeOperations(operations, handler: { (error) in
                    completionHandler(error)
                })
            } else {
                let requestAndOperations = try self.subreddit!.submitRequestAndOperations(title, kind: kind, context: context, authenticationController: authenticationController)
                let operations = requestAndOperations.operations
                let request = requestAndOperations.request
                request.sendReplies = self.sendReplies
                request.resubmit = self.resubmit
                dataController.executeAndSaveOperations(operations, context: context) { (error) in
                    completionHandler(error)
                }
            }
            
        } catch let error as NSError {
            completionHandler(error)
            return
        } catch {
            completionHandler(NSError.beamError(localizedDescription: "Unknown error"))
            return
        }
    }
    
}

extension CreatePostViewController: BeamModalPresentation {

    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return BeamModalPresentationStyle.formsheet
    }
}
