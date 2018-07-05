//
//  CreateLinkPostViewController.swift
//  Beam
//
//  Created by Rens Verhoeven on 25-03-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

import UIKit
import Snoo

class CreateLinkPostViewController: CreatePostViewController {

    var animateKeyboardAppearance = false
    
    @IBOutlet var titleTextField: UITextField?
    @IBOutlet var linkTextField: UITextField?
    @IBOutlet var seperatorView: UIView!
    @IBOutlet var seperatorViewHeightConstaint: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewContentView: UIView!
    
    @IBOutlet var recentLinkControl: RecentLinkPopupButton!
    @IBOutlet var inlineRecentLinkView: UIView!
    @IBOutlet var linkToRecentLinkConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = AWKLocalizedString("link-post-title")

        self.titleTextField?.delegate = self
        self.linkTextField?.delegate = self
        self.linkTextField?.keyboardType = UIKeyboardType.URL
        
        self.configureRecentLink()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.titleTextField?.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.animateKeyboardAppearance = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.titleTextField?.resignFirstResponder()
        self.linkTextField?.resignFirstResponder()
    }

    fileprivate func configureRecentLink() {
        if let URL = UIPasteboard.general.url {
            self.linkTextField?.rightView = self.inlineRecentLinkView
            self.linkTextField?.rightViewMode = UITextFieldViewMode.always
            
            self.recentLinkControl.isHidden = false
            self.linkToRecentLinkConstraint.isActive = true
            
            self.recentLinkControl.addTarget(self, action: #selector(CreateLinkPostViewController.hideRecentLink(_:)), for: UIControlEvents.editingDidEnd)
            self.recentLinkControl.link = URL.absoluteString
        } else {
            self.hideRecentLink(nil)
        }
    }
    
    @IBAction fileprivate func recentLinkTapped(_ sender: AnyObject) {
        self.linkTextField?.text = UIPasteboard.general.url?.absoluteString
        self.updateSubmitStatus()
        self.linkTextField?.rightView = nil
        self.hideRecentLink(sender)
    }
    
    @objc fileprivate func hideRecentLink(_ sender: AnyObject?) {
        
        self.recentLinkControl.isHidden = true
        self.linkToRecentLinkConstraint.isActive = false
        self.scrollView.layoutIfNeeded()
    }
    
    // MARK: Actions
    
    override func submitTapped(_ sender: AnyObject) {
        guard self.linkIsValidURL(self.linkTextField?.text ?? "") == true else {
            let alertController = BeamAlertController(alertWithCloseButtonAndTitle: AWKLocalizedString("invalid-link-error-title"), message: AWKLocalizedString("invalid-link-error-message"))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        super.submitTapped(sender)
    }
    
    fileprivate func linkIsValidURL(_ link: String) -> Bool {
        guard link.count > 0 else {
            return false
        }
        if (link.hasPrefix("https://") || link.hasPrefix("http://") || link.hasPrefix("www.")) && URL(string: link) != nil {
            let url = URL(string: link)!
            if url.host == nil {
                return false
            }
            return true
        } else {
            return false
        }
    }
    
    // MARK: Notifications
    
    override func keyboardDidChangeFrame(_ frame: CGRect, animationDuration: TimeInterval, animationCurveOption: UIViewAnimationOptions) {
        let bottomInset: CGFloat = max(self.view.bounds.height - frame.minY, 0)
        
        if self.animateKeyboardAppearance == false {
            UIView.performWithoutAnimation({
                self.applyScrollViewBottomInset(bottomInset)
            })
        } else {
            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurveOption, animations: {
                //ANIMATE
                self.applyScrollViewBottomInset(bottomInset)
            }, completion: nil)
        }
        
    }
    
    fileprivate func applyScrollViewBottomInset(_ bottomInset: CGFloat) {
        var contentInset = self.scrollView.contentInset
        contentInset.bottom = bottomInset
        self.scrollView.contentInset = contentInset
        self.scrollView.scrollIndicatorInsets = contentInset
        self.view.layoutIfNeeded()
    }
    
    override func textfieldDidChange(_ textField: UITextField) {
        
    }
    
    // MARK: Display Mode
    
    override func displayModeDidChange() {
        super.displayModeDidChange()
        
        let backgroundColor = DisplayModeValue(UIColor.white, darkValue: UIColor.beamDarkContentBackgroundColor())
        self.view.backgroundColor = backgroundColor
        self.scrollViewContentView.backgroundColor = backgroundColor
        self.scrollView.backgroundColor = backgroundColor
        
        let placeholderColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white).withAlphaComponent(0.5)
        self.titleTextField?.attributedPlaceholder = NSAttributedString(string: AWKLocalizedString("post-title-placeholder"), attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        self.linkTextField?.attributedPlaceholder = NSAttributedString(string: AWKLocalizedString("post-link-placeholder"), attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        
        let textColor = DisplayModeValue(UIColor.black, darkValue: UIColor.white)
        self.titleTextField?.textColor = textColor
        self.linkTextField?.textColor = textColor
        
        let keyboardAppearance = DisplayModeValue(UIKeyboardAppearance.default, darkValue: UIKeyboardAppearance.dark)
        self.titleTextField?.keyboardAppearance = keyboardAppearance
        self.linkTextField?.keyboardAppearance = keyboardAppearance
        
        self.seperatorView.backgroundColor = DisplayModeValue(UIColor(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 1), darkValue: UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1))
    }
    
    // MARK: CreatePostViewController properties and functions
    
    override var canSubmit: Bool {
        guard let title = self.titleTextField?.text, let link = self.linkTextField?.text else {
            return false
        }
        return self.subreddit != nil && title.count > 0 && link.count > 0
    }
    
    override var hasContent: Bool {
        let title = self.titleTextField?.text ?? ""
        let link = self.linkTextField?.text ?? ""
        return title.count > 0 || link.count > 0
    }
    
    override internal var postKind: RedditSubmitKind {
        var urlString = self.linkTextField?.text ?? ""
        if urlString.hasPrefix("www.") {
            urlString = "http://\(urlString)"
        }
        return RedditSubmitKind.link(URL(string: urlString)!)
    }
    
    override internal var postTitle: String {
        return self.titleTextField?.text ?? ""
    }
    
    override func didStartSubmit() {
        self.lockView(true)
    }
    
    override func lockView(_ locked: Bool) {
        super.lockView(locked)
        let alpha: CGFloat = locked ? 0.5: 1.0
        self.titleTextField?.isEnabled = !locked
        self.titleTextField?.alpha = alpha
        self.linkTextField?.isEnabled = !locked
        self.linkTextField?.alpha = alpha
        if locked {
            self.titleTextField?.resignFirstResponder()
            self.linkTextField?.resignFirstResponder()
        }
    }

}

extension CreateLinkPostViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == self.linkTextField && textField.text?.count == 0 {
            textField.text = "http://"
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.linkTextField && textField.text == "http://" && (string == UIPasteboard.general.string || string == UIPasteboard.general.url?.absoluteString) {
            textField.text = nil
        }
        if textField == self.linkTextField && string == UIPasteboard.general.string && !string.contains("http") {
            textField.text = "http://\(string)"
            return false
        }
        if textField == self.titleTextField {
            let currentCharacterCount = textField.text?.count ?? 0
            if range.length + range.location > currentCharacterCount {
                return false
            }
            let newLength = currentCharacterCount + string.count - range.length
            return newLength <= 300
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.linkTextField && textField.text == "http://" {
            textField.text = nil
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.titleTextField {
            self.linkTextField?.becomeFirstResponder()
        } else if textField == self.linkTextField {
            self.linkTextField?.resignFirstResponder()
        }
        return false
    }
    
}
