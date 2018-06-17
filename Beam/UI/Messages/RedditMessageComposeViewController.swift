//
//  RedditMessageComposeViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 07/12/2016.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo
import SDWebImage
import CoreData
import Trekker

class RedditMessageComposeViewController: BeamViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var subjectTextField: UITextField!
    @IBOutlet var textView: UITextView!
    @IBOutlet var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var textViewPlaceholderLabel: UILabel!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewContentView: UIView!
    
    @IBOutlet var seperatorView: UIView!
    @IBOutlet var seperatorViewHeightConstaint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    /// The user sending the message to. Must always be filled
    var user: User!
    
    /// The message in case the user replies to a message
    var message: Message?
    
    /// If the view is currently in the process of sending a message
    fileprivate var isSending: Bool = false
    
    /// If you meet all requirements to send a message
    internal var canSend: Bool {
        let message = self.textView.text.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        guard let subject = self.subjectTextField.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) else {
            return false
        }
        return self.user != nil && subject.count > 0 && message.count > 0
    }
    
    /// If the view has content, used in case the user wants to close the view
    internal var hasContent: Bool {
        return (self.subjectTextField.text?.count ?? 0) > 0 || self.textView.text.count > 0
    }
    
    // MARK: - View Lifecyle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.user == nil {
            fatalError("User must be set before viewDidLoad")
        }
        
        //Set the title of the view
        if let username = self.user.username {
            self.title = NSLocalizedString("new-message-view-title", comment: "The new message view title with [USERNAME]").replacingLocalizablePlaceholders(for: ["username": username])
        } else {
            self.title = NSLocalizedString("new-message-view-title-no-username", comment: "The new message view title without username")
        }
        
        //Set the height of the seperator view
        self.seperatorViewHeightConstaint.constant = 1 / UIScreen.main.scale
        
        //Set the placeholder that is behind the message text field
        self.textViewPlaceholderLabel.text = NSLocalizedString("your-message-placeholder", comment: "The placeholder behind the text field for your message")
        
        //Remove the textView insets
        self.textView.textContainerInset = UIEdgeInsets.zero
        self.textView.textContainer.lineFragmentPadding = 0
        
        //Set the text fields/views delegates
        self.textView.delegate = self
        self.subjectTextField.delegate = self
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navigationbar_close"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(RedditMessageComposeViewController.cancelTapped(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("send-button", comment: "Generic send button"), style: UIBarButtonItemStyle.done, target: self, action: #selector(RedditMessageComposeViewController.sendTapped(_:)))
        
        //Subscribe to notifications
        NotificationCenter.default.addObserver(self, selector: #selector(RedditMessageComposeViewController.textFieldTextDidChange(notification:)), name: Notification.Name.UITextFieldTextDidChange, object: self.subjectTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(RedditMessageComposeViewController.keyboardDidChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RedditMessageComposeViewController.keyboardDidChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        
        //We don't want to be able to pan to close the view
        if let navigationController = self.navigationController as? BeamNavigationController {
            navigationController.useInteractiveDismissal = false
        }
        
        self.reloadSendButton()
    }
    
    // MARK: - Actions
    
    @IBAction internal func cancelTapped(_ sender: AnyObject) {
        if self.hasContent {
            let title = NSLocalizedString("discard-message-alert-title", comment: "The message shown when the user is trying to cancel the view when creating a message")
            let message = NSLocalizedString("discard-message-alert-message", comment: "The message shown when the user is trying to cancel the view when creating a message")
            let alertController = BeamAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("discard-button", comment: "Generic discard button"), style: UIAlertActionStyle.destructive, handler: { (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("keep-button", comment: "Generic keep button"), style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction internal func sendTapped(_ sender: AnyObject) {
        self.startSending()
        
    }
    
    // MARK: - Notifications
    
    @objc fileprivate func textFieldTextDidChange(notification: Notification) {
        self.reloadSendButton()
    }
    
    @objc fileprivate func keyboardDidChangeFrame(notification: Notification) {
        let frame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = ((notification as NSNotification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as? NSNumber ?? NSNumber(value: 0 as Double)).doubleValue
        var animationCurveOption: UIViewAnimationOptions = UIViewAnimationOptions()
        if (notification as NSNotification).userInfo?[UIKeyboardAnimationCurveUserInfoKey] != nil {
            ((notification as NSNotification).userInfo![UIKeyboardAnimationCurveUserInfoKey]! as AnyObject).getValue(&animationCurveOption)
        }
        let keyboardFrame = self.view.convert(frame, from: nil)
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurveOption, animations: {
            //ANIMATE
            let bottomInset: CGFloat = max(self.view.bounds.height - keyboardFrame.minY, 0)
            var contentInset = self.scrollView.contentInset
            contentInset.bottom = bottomInset
            self.scrollView.contentInset = contentInset
            self.scrollView.scrollIndicatorInsets = contentInset
            UIView.performWithoutAnimation({
                self.sizeTextView()
                self.view.layoutIfNeeded()
            })
            
        }, completion: nil)
    }
    
    // MARK: - Utils
    
    internal func reloadSendButton() {
        self.navigationItem.rightBarButtonItem?.isEnabled = self.canSend && self.isSending == false
    }
    
    // MARK: - Display Mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
            
        let backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.view.backgroundColor = backgroundColor
        self.scrollViewContentView.backgroundColor = backgroundColor
        self.scrollView.backgroundColor = backgroundColor
        
        let placeholderColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        self.subjectTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("subject-placeholder", comment: "Placeholder for the subject of a message"), attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        self.textViewPlaceholderLabel.textColor = placeholderColor
        
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.subjectTextField.textColor = textColor
        self.textView.textColor = textColor
        
        let keyboardAppearance = DisplayModeValue(UIKeyboardAppearance.default, darkValue: UIKeyboardAppearance.dark)
        self.subjectTextField.keyboardAppearance = keyboardAppearance
        self.textView.keyboardAppearance = keyboardAppearance
        
        self.seperatorView.backgroundColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
    }
    
    // MARK: - Layout
    
    fileprivate func sizeTextView() {
        guard let navigationController = self.navigationController else {
            return
        }
        var minimumHeight = self.scrollView.frame.height
        minimumHeight -= navigationController.navigationBar.frame.height
        minimumHeight -= self.scrollViewContentView.layoutMargins.top
        minimumHeight -= self.scrollViewContentView.layoutMargins.bottom
        minimumHeight -= self.subjectTextField.intrinsicContentSize.height
        minimumHeight -= self.scrollView.contentInset.bottom
        minimumHeight -= 40 //Action bar
        self.textViewHeightConstraint.constant = max(self.textView.sizeThatFits(CGSize(width: self.textView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height, minimumHeight)
        self.scrollView.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.sizeTextView()
    }
    
    // MARK: - Blocking user action while posting
    
    func lockView(_ locked: Bool) {
        self.navigationItem.leftBarButtonItem?.isEnabled = !locked
        self.navigationItem.rightBarButtonItem?.isEnabled = !locked
    }
    
    // MARK: - State changes
    
    /// Called when the submit starts
    internal func didStartSubmit() {
        
    }
    
    /// Called when an error occurs or the sending is finished
    internal func didFinishSending(_ error: Error?, cancelled: Bool) {
        if error != nil || cancelled == true {
            self.lockView(false)
            if let error = error {
                self.handleError(error)
            }
        } else {
            self.dismiss(animated: true, completion: {
                if let noticeHandler = AppDelegate.topViewController() as? NoticeHandling {
                    noticeHandler.presentSuccessMessage(NSLocalizedString("message-successfully-sent", comment: "Banner message when a message was successfully sent"))
                }
            })
        }
    }
    
    internal func handleError(_ error: Error) {
        DispatchQueue.main.async {
            let alertController = BeamAlertController(alertWithCloseButtonAndTitle: NSLocalizedString("message-send-error-title", comment: "Generic title of the error message when sending a message fails"), message: error.localizedDescription)
            let nsError = error as NSError
            if nsError.domain == BeamErrorDomain {
                switch nsError.code {
                case -401:
                    alertController.title = NSLocalizedString("invalid-subject-error-title", comment: "Invalid message subject error title")
                    alertController.message = NSLocalizedString("invalid-subject-error-message", comment: "Invalid message subject error message")
                case -402:
                    alertController.title = NSLocalizedString("invalid-message-text-error-title", comment: "Invalid message text error title")
                    alertController.message = NSLocalizedString("invalid-message-text-error-message", comment: "Invalid message text error message")
                default:
                    alertController.message = nsError.localizedDescription
                }
            } else if let redditError = nsError.redditErrorKey {
                switch redditError {
                case .BadCaptcha:
                    alertController.title = NSLocalizedString("incorrect-captcha-error-title", comment: "Title of the message when the captcha was incorrect for sending a message of submitting a post")
                    alertController.message = NSLocalizedString("incorrect-captcha-error-message", comment: "Message when the captcha was incorrect for sending a message of submitting a post")
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("retry-button", comment: "Generic retry button"), style: UIAlertActionStyle.default, handler: { (_) in
                        self.startSending()
                    }))
                case .RateLimited:
                    alertController.title = NSLocalizedString("rate-limited-error-title", comment: "Title of the message when the user or app is being rate limited")
                    alertController.message = NSLocalizedString("rate-limited-error-message", comment: "The message when the user or app is being rate limited")
                default:
                    AWKDebugLog("reddit error not translated: %@", redditError.rawValue)
                }
            }
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    // MARK: - Message sending
    
    fileprivate func startSending() {
        self.didStartSubmit()
        self.isSending = true
        self.performSending()
    }
    
    fileprivate func performSending() {
        let subject = self.subjectTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
        let message = self.textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        self.sendMessage(to: self.user, subject: subject, message: message) { (error) in
            DispatchQueue.main.async(execute: {
                self.isSending = false
                self.didFinishSending(error, cancelled: false)
            })
        }
    }
    
    fileprivate func sendMessage(to: User, subject: String, message: String, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        guard subject.trimmingCharacters(in: CharacterSet.whitespaces).count != 0 else {
            completionHandler(NSError.beamError(-401, localizedDescription: "Subject missing"))
            return
        }
        guard message.trimmingCharacters(in: CharacterSet.whitespaces).count != 0 else {
            completionHandler(NSError.beamError(-402, localizedDescription: "Text missing"))
            return
        }
        
        let authenticationController = AppDelegate.shared.authenticationController
        let dataController = DataController.shared
        let context: NSManagedObjectContext! = AppDelegate.shared.managedObjectContext
        do {
            let requestAndOperations = try self.user.redditMessageComposeOperation(subject: subject, message: message, authenticationController: authenticationController)
            let operations = requestAndOperations.operations
            dataController.executeAndSaveOperations(operations, context: context) { (error) in
                completionHandler(error)
                DispatchQueue.main.async {
                    if error == nil {
                        Trekker.default.track(event: TrekkerEvent(event: "Send reddit message", properties: ["Type": "New"]))
                    }
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

// MARK: - UITextViewDelegate

extension RedditMessageComposeViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        self.reloadSendButton()
        self.textViewPlaceholderLabel.isHidden = self.textView.text.count > 0
        
        self.sizeTextView()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        //15000 is the character limit for self text posts and messages
        return textView.text.count + (text.count - range.length) <= 15000
    }
    
}

// MARK: - UITextFieldDelegate

extension RedditMessageComposeViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.subjectTextField {
            let currentCharacterCount = textField.text?.count ?? 0
            if range.length + range.location > currentCharacterCount {
                return false
            }
            let newLength = currentCharacterCount + string.count - range.length
            //300 is the maximum length of a message subject of post title
            return newLength <= 300
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.subjectTextField {
            self.textView.becomeFirstResponder()
        }
        return false
    }
    
}

extension RedditMessageComposeViewController: BeamModalPresentation {
    
    var preferredModalPresentationStyle: BeamModalPresentationStyle {
        return BeamModalPresentationStyle.formsheet
    }
}
